#!/bin/bash
T=/root/star26/star-native
B=$T/BUILD/obj/RELEASE_ARM64_BCM2837
NM=/root/star-build/xnu-deps/host/bin/nm
echo "=== 引用 _console_write 的目标文件"
for f in $(find "$B" -name '*.o' 2>/dev/null); do
  if "$NM" -u "$f" 2>/dev/null | grep -q '_console_write$'; then echo "  $f"; fi
done
echo
echo "=== serial_general.o 是否定义 console_printbuf_putc / 引用 loader_log_putc"
SG=$(find "$B" -name 'serial_general.o' | head -1); echo "  $SG"
"$NM" "$SG" 2>/dev/null | grep -i 'console_printbuf_putc\|console_write' | head
echo
echo "=== IOLib.o 引用情况"
IL=$(find "$B" -name 'IOLib.o' | head -1); echo "  $IL"
"$NM" -u "$IL" 2>/dev/null | grep -i 'console_write\|console_printbuf\|disable_iolog' | head
echo
echo "=== printf.o 引用"
PR=$(find "$B" -name 'printf.o' | head -1); echo "  $PR"
"$NM" -u "$PR" 2>/dev/null | grep -i 'console_write\|console_printbuf\|PE_kputc' | head
