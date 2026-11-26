#!/bin/bash
echo "=== 1. starcat 二进制是否存在 ==="
ls -la /root/star26/s39/work/starcat 2>/dev/null || echo "NO s39 starcat"
find /root/star26 -name starcat -type f 2>/dev/null | head -10
echo
echo "=== 2. 当前 s65 ramdisk 里有哪些 /annibale/bin 工具 ==="
for d in /root/star26/s64 /root/star26/s65; do
  echo "--- $d/work ---"
  ls -la $d/work/annibale/bin/ 2>/dev/null | grep -iE "starcat|lsprobe|logd" || true
done
echo
echo "=== 3. ramdisk 构建脚本 repack-ramdisk.sh ==="
sed -n '1,60p' /mnt/d/桌面/star26-deps/scripts/repack-ramdisk.sh 2>/dev/null
echo
echo "=== 4. s50 完整 launchd 注入配置（了解 starcat 如何被拉起） ==="
sed -n '1,40p' /mnt/d/桌面/star26-deps/scripts/mks50.sh 2>/dev/null
