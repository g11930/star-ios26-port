#!/bin/bash
T=/root/star26/star-native
O=$T/BUILD/obj/RELEASE_ARM64_BCM2837/osfmk/console/serial_console.o
echo "--- serial_console.c"; ls -la --time-style=+%m-%d_%H:%M "$T/osfmk/console/serial_console.c"
echo "--- serial_console.o"; ls -la --time-style=+%m-%d_%H:%M "$O"
echo "--- .o 里对 loader_log_putc 的引用"
nm -u "$O" 2>/dev/null | grep -i 'loader_log' || echo "  (无引用)"
echo "--- 源码里 console_write 是否调 loader_log_putc"
grep -n 'loader_log_putc' "$T/osfmk/console/serial_console.c"
echo "--- 内核镜像里的 loader_log 符号"
nm "$T/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837" 2>/dev/null | grep -i ' loader_log' | head
echo "--- osfmk/console 目录下目标文件时间"
ls -la --time-style=+%m-%d_%H:%M "$T/BUILD/obj/RELEASE_ARM64_BCM2837/osfmk/console/" | head -20
