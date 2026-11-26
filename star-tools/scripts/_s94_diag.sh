#!/bin/bash
B=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837
echo "=== built kernel ==="
stat -c '%s bytes  %y' "$B"
echo "=== strings in built kernel ==="
for s in star_cs_keep_valid P28EXIT CODE_SIGNING star_cs_probe; do
  echo -n "$s: "; strings -a "$B" | grep -c "$s"
done
echo "=== source patch count ==="
grep -c "star_cs_keep_valid" /root/star26/star-native/bsd/kern/kern_cs.c
echo "=== object file ==="
O=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/bsd/RELEASE/kern_cs.o
stat -c '%s bytes  %y  %n' "$O"
echo -n "star_cs_keep_valid in .o: "; strings -a "$O" | grep -c "star_cs_keep_valid"
echo "=== all mach.release kernels ==="
find /root/star26/star-native/BUILD -name 'mach.release*' -type f -printf '%s  %TY-%Tm-%Td %TH:%TM  %p\n' 2>/dev/null
