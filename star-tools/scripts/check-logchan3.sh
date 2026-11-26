#!/bin/bash
D=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/osfmk/RELEASE
echo "--- serial_console.o 未定义符号里的 loader_log*"
nm -u "$D/serial_console.o" | grep -i loader || echo "  (无)"
echo "--- loader_return.o 导出的 loader_log 符号"
nm "$D/loader_return.o" | grep -i 'loader_log\|loader_jump' | head -10
echo "--- printf.o 是否引用 loader_log"
nm -u "$D/printf.o" 2>/dev/null | grep -i loader || echo "  (无)"
