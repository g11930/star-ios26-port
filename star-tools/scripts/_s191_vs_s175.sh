#!/bin/bash
cd /mnt/c/ios26
for img in s175 s191; do
  echo "########## $img ##########"
  python3 /mnt/d/桌面/star26-deps/scripts/xnup_info.py ${img}-boot.img 2>&1 | grep -E "kernel|ramdisk|cmdline|md5|name" | head -12
  echo
done
