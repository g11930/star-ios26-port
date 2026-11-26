#!/bin/bash
K=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837.unstripped.noctf
# 找 cs_validate_range 在全内核被谁调用
echo "=== cs_validate_range 符号 ==="
llvm-nm "$K" 2>/dev/null | grep -i 'cs_validate_range'
echo "=== 反汇编里 cs_validate_range 调用点（哪个函数）==="
llvm-objdump -d "$K" 2>/dev/null | grep -B2 -i 'cs_validate_range' | head -20
echo "=== load_machfile 里 adrp 到 star_cs_keep_valid 页 (0xfffffff007ade000) ==="
# star_cs_keep_valid @ fffffff007adefb4 => adrp page = fffffff007ade000
grep -inE 'adrp.*7ade|7adefb4|0xfb4' /tmp/s212_lm.asm | head -20
echo "=== load_machfile 里 bic (CS_VALID 清除) 上下文 ==="
grep -n 'bic' /tmp/s212_lm.asm | head -20
