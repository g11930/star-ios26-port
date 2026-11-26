#!/bin/bash
K=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837.unstripped.noctf
llvm-objdump -d "$K" 2>/dev/null > /tmp/s212_all.asm
# cs_validate_range 调用点 0xfffffff0072c877c，打印其后 60 行（含 CS_VALID 清除与条件）
echo "=== cs_validate_range 调用后 60 行 ==="
grep -n '0xfffffff0072c877c' /tmp/s212_all.asm | head -1
START=$(grep -n 'fffffff0072c877c:' /tmp/s212_all.asm | head -1 | cut -d: -f1)
echo "line=$START"
sed -n "$((START-3)),$((START+70))p" /tmp/s212_all.asm
