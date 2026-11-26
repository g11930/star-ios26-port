#!/bin/bash
T=/root/star26/star-native
echo "--- 找 serial_console.o"
find "$T/BUILD" -name 'serial_console.o' -printf '%TY-%Tm-%Td_%TH:%TM  %10s  %p\n' 2>/dev/null | head
echo "--- 找 loader_return.o"
find "$T/BUILD" -name 'loader_return.o' -printf '%TY-%Tm-%Td_%TH:%TM  %10s  %p\n' 2>/dev/null | head
echo "--- 内核镜像"
ls -la --time-style=+%m-%d_%H:%M "$T/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837" 2>/dev/null
echo "--- 镜像里的 loader_log 相关符号"
K="$T/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837"
strings -a "$K" | grep -c . >/dev/null
nm -a "$K" 2>/dev/null | grep -i 'loader_log\|loader_jump' | head
echo "--- 镜像里是否含 star: milestone 文本"
strings -a "$K" | grep -c 'star: milestone' || true
