#!/bin/bash
# star_cs_keep_valid 全局 @ 0xfffffff007adefb4, adrp 页基 0xfffffff007ade000
echo "=== 全内核 adrp 到 0xfffffff007ade000 页 ==="
grep -inE 'adrp[^#]*0xfffffff007ade000|adrp.*7ade' /tmp/s212_all.asm | head -20
echo "=== 直接搜地址符号化形式（各种大小写）==="
grep -inE 'adefb4|7adefb4' /tmp/s212_all.asm | head -20
echo "=== parse_machfile 符号地址 ==="
llvm-nm /root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837.unstripped.noctf 2>/dev/null | grep -iE ' parse_machfile$| _parse_machfile'
