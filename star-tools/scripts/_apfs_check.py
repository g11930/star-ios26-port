import sys, subprocess
sys.path.insert(0, '/root/star-build/tools/apfs')
import apfs

c = apfs.Container('/root/star26/s111/root19.apfs')
v = c.volumes()[0]
for p in ['/etc/sbmetal-late', '/lib/libsbtrace.dylib', '/lib/libannibale-sbmetal-experiment.dylib']:
    try:
        ino = v.lookup(p)
        print(p, 'ino', ino, 'size', v.inode(ino).size)
    except Exception as e:
        print(p, 'MISSING', e)

d = v.inode(v.lookup('/lib/libsbtrace.dylib')).contents()
open('/tmp/sbtrace-from-apfs.dylib', 'wb').write(d)
print('sbtrace', len(d), 'has late marker:', b'late: %s air resident' in d)
