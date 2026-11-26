#!/bin/bash
K=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837.unstripped.noctf
echo "=== llvm-nm: star_cs_keep_valid ==="
llvm-nm "$K" 2>/dev/null | grep -i 'star_cs_keep_valid'
echo "=== llvm-nm: s212 sentinel ==="
llvm-nm "$K" 2>/dev/null | grep -i 's212'
echo "=== llvm-nm: load_machfile ==="
llvm-nm "$K" 2>/dev/null | grep -i 'load_machfile'
echo "=== llvm-nm 符号总数 ==="
llvm-nm "$K" 2>/dev/null | wc -l
