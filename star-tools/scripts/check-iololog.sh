#!/bin/bash
T=/root/star26/star-native
echo "=== 全树搜 IOLog 的定义（行首或函数体）"
grep -rn --include=*.c --include=*.cpp --include=*.h 'IOLog(const char' "$T" | grep -v BUILD | head -20
echo
echo "=== disable_iolog_serial_output 的赋值点"
grep -rn --include=*.c --include=*.cpp 'disable_iolog_serial_output *=' "$T" | grep -v BUILD | head -20
echo
echo "=== disable_serial_output / disable_kprintf_output 赋值点"
grep -rn --include=*.c --include=*.cpp 'disable_serial_output *=\|disable_kprintf_output *=' "$T" | grep -v BUILD | head -20
echo
echo "=== bcm2837_board_stubs.c 里是否顶掉 IOLog"
grep -n 'IOLog' "$T/bsd/dev/bcm2837/bcm2837_board_stubs.c" 2>/dev/null || echo "  (无)"
