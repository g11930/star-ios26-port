#!/bin/bash
K=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837.unstripped.noctf
# star_cs_keep_valid 全局地址
KV=$(llvm-nm "$K" 2>/dev/null | grep ' _star_cs_keep_valid$' | awk '{print $1}')
echo "star_cs_keep_valid @ $KV"
# load_machfile 地址与大小
LM=$(llvm-nm "$K" 2>/dev/null | grep ' _load_machfile$' | awk '{print $1}')
echo "load_machfile @ $LM"
echo "=== 全内核反汇编中引用 star_cs_keep_valid 地址的位置 ==="
llvm-objdump -d --symbolize-operands "$K" 2>/dev/null | grep -i "star_cs_keep_valid" | head -30
echo "=== 也试 adrp 目标形式（地址低12位）==="
# arm64 adrp+add 引用全局，符号化后应显示符号名；上条若无结果则说明编译器把读取内联到别处
