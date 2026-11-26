#!/bin/bash
T=/root/star26/star-native
echo "=== console_write 的所有定义"
grep -rn --include=*.c --include=*.cpp 'console_write(char\|console_write_unbuffered(char' "$T" | grep -v BUILD
echo
echo "=== 哪些 .o 定义了 console_write（llvm-nm）"
NM=/root/star-build/xnu-deps/host/bin/nm
for f in $(find "$T/BUILD/obj/RELEASE_ARM64_BCM2837" -name '*.o' 2>/dev/null); do
  if "$NM" "$f" 2>/dev/null | grep -q ' T _console_write$'; then echo "  $f"; fi
done
echo
echo "=== 引用 console_write 的 .o 数"
c=0
for f in $(find "$T/BUILD/obj/RELEASE_ARM64_BCM2837" -name '*.o' 2>/dev/null); do
  if "$NM" -u "$f" 2>/dev/null | grep -q '_console_write$'; then c=$((c+1)); fi
done
echo "  $c"
