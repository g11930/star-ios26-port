#!/bin/bash
T=/root/star26/star-native
B=$T/BUILD/obj/RELEASE_ARM64_BCM2837
echo "=== 构建产物里的 map/symbols 文件"
find "$B" -maxdepth 1 -type f \( -name '*.map' -o -name '*.symbols' -o -name '*.txt' -o -name '*.sym' \) -printf '%s %p\n' 2>/dev/null | head
echo "=== 内核二进制的符号表里有 IOLog 吗（objdump 符号表）"
OD=/root/star-build/xnu-deps/host/bin/objdump
K="$B/mach.release.bcm2837"
"$OD" -t "$K" 2>/dev/null | grep -i 'IOLog\|loader_log' | head
echo "=== star_display_milestone 反汇编（看它调的是什么）"
"$OD" -d --disassemble-symbols=_star_display_milestone "$K" 2>/dev/null | head -40
