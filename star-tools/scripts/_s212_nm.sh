#!/bin/bash
K=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837.unstripped.noctf
echo "=== file ==="
file "$K"
echo "=== star_cs_keep_valid (nm) ==="
nm "$K" 2>/dev/null | grep -i 'star_cs_keep_valid'
echo "=== s212 sentinel (nm) ==="
nm "$K" 2>/dev/null | grep -i 's212'
echo "=== load_machfile (nm) ==="
nm "$K" 2>/dev/null | grep -i 'load_machfile'
echo "=== nm 总符号数 ==="
nm "$K" 2>/dev/null | wc -l
