import sys
sys.path.insert(0, "/root/star-build/tools/apfs")
import apfs

for path in ("/root/star26/s111/parts/ramdisk", "/root/star26/s110/parts/ramdisk"):
    c = apfs.Container(path)
    v = c.volumes()[0]
    ino = v.lookup("/etc/inject.conf")
    if ino is None:
        print(path, "inject.conf missing")
        continue
    ino = ino[0] if isinstance(ino, tuple) else ino
    data = v.inode(ino).contents()
    print("==", path, len(data), "bytes")
    print(data.decode("utf-8", "replace").strip())
    print()
