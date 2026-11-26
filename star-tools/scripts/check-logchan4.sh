#!/bin/bash
D=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/osfmk/RELEASE
NM=/root/star-build/xnu-deps/host/bin/llvm-nm
[ -x "$NM" ] || NM=$(ls /root/star-build/xnu-deps/host/bin/*nm* 2>/dev/null | head -1)
echo "nm=$NM"
echo "--- serial_console.o 未定义符号（找 loader_log_putc）"
"$NM" -u "$D/serial_console.o" 2>&1 | grep -i 'loader' || echo "  (无)"
echo "--- serial_console.o 已定义符号（找 console_write）"
"$NM" "$D/serial_console.o" 2>&1 | grep -w 'console_write\|console_write_unbuffered' | head
echo "--- loader_return.o 的 loader_log 系列"
"$NM" "$D/loader_return.o" 2>&1 | grep -i 'loader_log\|loader_jump' | head
