#!/bin/bash
echo "=== A. s91 / s92 目录内容 ==="
ls -l /root/star26/s91/ /root/star26/s92/ 2>&1
echo
echo "=== B. s92 内核里是否含 MetalPluginName 字符串 ==="
for d in s91 s92 s90; do
  k=/root/star26/$d/parts/kernel
  if [ -f "$k" ]; then
    echo "--- $d ($(stat -c '%y %s' $k)) ---"
    strings -a "$k" 2>/dev/null | grep -c 'MetalPluginName'
    strings -a "$k" 2>/dev/null | grep 'IOAcceleratorES: publish\|MetalPluginName\|CS_INITPAGE' | head -10
  else
    echo "--- $d: no kernel ---"
  fi
done
echo
echo "=== C. 找 s92 boot.img / staged ==="
find /root/star26 /root/star26-deps -maxdepth 3 -name '*s92*' -o -maxdepth 3 -name '*staged*' 2>/dev/null | head -20
echo
echo "=== D. D:\\桌面 下 star26 产物 ==="
ls -lt /mnt/d/桌面/star26-deps/ 2>/dev/null | head -20
ls -lt /mnt/d/桌面/ 2>/dev/null | grep -i 's9\|staged\|bin' | head -20
echo "=== DONE ==="
