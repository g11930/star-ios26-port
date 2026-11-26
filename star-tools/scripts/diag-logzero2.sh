#!/bin/bash
T=/root/star26/star-native
OBJ=$T/BUILD/obj/RELEASE_ARM64_BCM2837/bsd/RELEASE
N=/root/star-build/xnu-deps/host/bin/nm

echo "=== snprintf / vsnprintf 定义处 ==="
grep -n '^vsnprintf\|^snprintf\|^int$' "$T/osfmk/kern/printf.c" | head -20
grep -n 'CONFIG_NO_PRINTF_STRINGS' "$T/osfmk/kern/printf.c" | head -20

echo "=== 宏定义位置（全树头文件） ==="
grep -rn 'define snprintf\|define vsnprintf\|define printf' "$T/bsd/sys" "$T/osfmk/kern" "$T/libkern" \
    --include=*.h 2>/dev/null | head -20

echo "=== 对象文件里的符号表（milestone / trace） ==="
$N "$OBJ/star_display_handoff.o" 2>/dev/null | grep -i -E 'milestone|star_log|loader_log' | head
$N "$OBJ/kern_exec.o" 2>/dev/null | grep -i -E 'star_trace|loader_log|snprintf' | head

echo "=== llvm-objdump 用法探测 ==="
llvm-objdump -d "$OBJ/star_display_handoff.o" 2>&1 | head -25

echo "=== 用 --macho + --disassemble-symbols ==="
llvm-objdump --macho --disassemble-symbols=_star_display_milestone "$OBJ/star_display_handoff.o" 2>&1 | head -35
