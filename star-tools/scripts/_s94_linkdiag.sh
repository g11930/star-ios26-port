#!/bin/bash
T=/root/star26/star-native
OBJ=$T/BUILD/obj/RELEASE_ARM64_BCM2837
echo "=== all kern_cs.o copies under BUILD ==="
find "$OBJ" -name 'kern_cs*.o' -printf '%s  %TY-%Tm-%Td %TH:%TM:%TS  %p\n' 2>/dev/null
echo "=== patch string in each ==="
for f in $(find "$OBJ" -name 'kern_cs*.o' 2>/dev/null); do
  echo -n "$(basename $f) @ $(dirname $f): "; strings -a "$f" | grep -c star_cs_keep_valid
done
echo "=== .a archive: list kern_cs members ==="
A=$OBJ/mach.release.bcm2837.link/mach.release.bcm2837.a
ls -la "$A" 2>/dev/null
/root/star-build/xnu-deps/host/bin/ar t "$A" 2>/dev/null | grep -i kern_cs || echo "(ar unavailable or none)"
echo -n "patch in .a: "; strings -a "$A" 2>/dev/null | grep -c star_cs_keep_valid
echo "=== compare with s93: what source md5 was kern_cs.c then? ==="
echo "current kern_cs.c md5:"; md5sum "$T/bsd/kern/kern_cs.c"
echo "backup (.s92.bak = pre-patch):"; md5sum "$T/bsd/kern/kern_cs.c.s92.bak"
echo "=== linkarguments: grep kern_cs ==="
grep -o 'kern_cs[^ ]*' "$OBJ/mach.release.bcm2837.link/mach.release.bcm2837.linkarguments" 2>/dev/null | head
