#!/bin/bash
B=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837
echo "=== all star_* strings in current kernel ==="
strings -a "$B" | grep 'star_' | sort -u
echo "=== count ==="
strings -a "$B" | grep -c 'star_'
echo "=== compare s93 kernel star_ strings ==="
strings -a /root/star26/s93/parts/kernel | grep 'star_' | sort -u
echo "=== binary compare current vs s93 kernel (first diff) ==="
cmp -l "$B" /root/star26/s93/parts/kernel 2>/dev/null | head -5
echo "=== sizes ==="
stat -c '%s %n' "$B" /root/star26/s93/parts/kernel
echo "=== nm: is star_cs_keep_valid symbol in unstripped? ==="
U=$B.unstripped.noctf
nm "$U" 2>/dev/null | grep -i 'star_cs_keep_valid\|star_cs_probe' || echo "(nm none)"
echo "=== unstripped strings ==="
strings -a "$U" | grep -c 'star_cs_keep_valid'
