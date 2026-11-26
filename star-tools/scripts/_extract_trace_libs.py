import sys, os
sys.path.insert(0, "/root/star-build/tools/apfs")
import apfs

SRC = "/root/star26/s110/parts/ramdisk"
DST = "/root/star26/s111/work/rootbuild/root/lib"

c = apfs.Container(SRC)
v = c.volumes()[0]
for name in ("/lib/liblogdtrace.dylib", "/lib/libsbtrace.dylib"):
    ino = v.lookup(name)
    if ino is None:
        print("MISSING", name)
        continue
    ino = ino[0] if isinstance(ino, tuple) else ino
    data = v.inode(ino).contents()
    out = os.path.join(DST, os.path.basename(name))
    open(out, "wb").write(data)
    print("wrote", out, len(data))

# also dump s110's inject.conf so we can diff against the one we are about to write
ino = v.lookup("/etc/inject.conf")
ino = ino[0] if isinstance(ino, tuple) else ino
print("== s110 inject.conf ==")
print(v.inode(ino).contents().decode("utf-8", "replace").strip())
