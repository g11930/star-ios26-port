#!/bin/bash
B=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837
U=$B.unstripped.noctf
O=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/bsd/RELEASE/kern_cs.o
echo "=== kernel ==="
stat -c '%s bytes  %y' "$B"
echo "=== exact strings: current built kernel (stripped) ==="
for s in star_cs_keep_valid cs_debug cs_enforcement_disable; do
  echo -n "  $s: "; strings -a "$B" | grep -cxE "$s"
done
echo "=== exact strings: unstripped ==="
for s in star_cs_keep_valid cs_debug cs_enforcement_disable; do
  echo -n "  $s: "; strings -a "$U" | grep -cxE "$s"
done
echo "=== kern_cs.o ==="
stat -c '%s bytes  %y' "$O"
for s in star_cs_keep_valid cs_debug; do
  echo -n "  $s: "; strings -a "$O" | grep -cxE "$s"
done
echo "=== source decl ==="
grep -n 'star_cs_keep_valid = 0' /root/star26/star-native/bsd/kern/kern_cs.c
echo "=== compare s93 ==="
for s in star_cs_keep_valid cs_debug; do
  echo -n "  s93 $s: "; strings -a /root/star26/s93/parts/kernel | grep -cxE "$s"
done
