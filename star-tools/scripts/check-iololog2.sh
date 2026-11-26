#!/bin/bash
T=/root/star26/star-native
B=$T/BUILD/obj/RELEASE_ARM64_BCM2837
NM=/root/star-build/xnu-deps/host/bin/nm
echo "=== 定义 _IOLog 的目标文件"
for f in $(find "$B" -name '*.o' 2>/dev/null); do
  if "$NM" -g "$f" 2>/dev/null | grep -qE ' T _IOLog$| T __IOLogv$'; then echo "  $f"; fi
done
echo "=== 引用 _IOLog 的目标文件（前 20）"
n=0
for f in $(find "$B" -name '*.o' 2>/dev/null); do
  if "$NM" -u "$f" 2>/dev/null | grep -q '_IOLog$'; then echo "  $f"; n=$((n+1)); fi
  if [ "$n" -ge 20 ]; then break; fi
done
echo "=== iokit 目录下的 .o 清单（前 30）"
find "$B/iokit" -name '*.o' 2>/dev/null | head -30
