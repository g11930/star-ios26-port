#!/bin/bash
F=/mnt/c/ios26/s49-staged.bin
echo "=== metal_dev 进程状态（lsprobe） ==="
grep -a "metal_dev" "$F" | tail -15
echo
echo "=== IOAcceleratorES 行号 ==="
grep -an "IOAcceleratorES" "$F" | head -3
echo
echo "=== IOAcceleratorES service published 之后 30 行 ==="
L=$(grep -an "service published" "$F" | head -1 | cut -d: -f1)
echo "line=$L"
sed -n "$((L+1)),$((L+30))p" "$F"
echo
echo "=== MobileGestalt 相关（metal 依赖它） ==="
grep -aiE "MobileGestalt|gestalt|GSService|com.apple.mobilegestalt" "$F" | grep -viE "plist|cmdline|boot-args" | head -20
