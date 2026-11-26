#!/bin/bash
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
for i in 1 2 3; do
  sleep 90
  $F -s xnuloader oem screenshot > /dev/null 2>&1
  $F -s xnuloader get_staged "C:/ios26/now-frame.raw" > /dev/null 2>&1
  python3 /mnt/d/桌面/star26-deps/scripts/fb2png.py /mnt/c/ios26/now-frame.raw /mnt/c/ios26/now-frame.png > /dev/null 2>&1
  echo "shot $i: $(stat -c %s /mnt/c/ios26/now-frame.png) bytes"
  cp /mnt/c/ios26/now-frame.png "/mnt/c/ios26/now-$i.png"
done