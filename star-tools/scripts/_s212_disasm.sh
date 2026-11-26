#!/bin/bash
K=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837.unstripped.noctf
# 反汇编 load_machfile，找对 _star_cs_keep_valid 的引用与附近 CS_VALID 处理
llvm-objdump --disassemble-symbols=_load_machfile --symbolize-operands "$K" 2>/dev/null > /tmp/s212_lm.asm
echo "=== load_machfile 反汇编行数 ==="
wc -l /tmp/s212_lm.asm
echo "=== 引用 star_cs_keep_valid 的指令 ==="
grep -n 'star_cs_keep_valid' /tmp/s212_lm.asm
echo "=== 上下文（每条引用前后 6 行） ==="
grep -n 'star_cs_keep_valid' /tmp/s212_lm.asm | cut -d: -f1 | while read ln; do
  lo=$((ln-6)); hi=$((ln+6))
  echo "--- around line $ln ---"
  sed -n "${lo},${hi}p" /tmp/s212_lm.asm
done
