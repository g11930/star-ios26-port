#!/bin/bash
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
for t in 120 180; do
  sleep $t
  $F -s xnuloader oem screenshot > /dev/null 2>&1
  $F -s xnuloader get_staged "C:/ios26/s175w-frame.raw" > /dev/null 2>&1
  python3 /mnt/d/桌面/star26-deps/scripts/fb2png.py /mnt/c/ios26/s175w-frame.raw /mnt/c/ios26/s175w-frame.png | tail -1
  s=$(stat -c %s /mnt/c/ios26/s175w-frame.png)
  cp /mnt/c/ios26/s175w-frame.png /mnt/c/ios26/s175w-${t}.png
  echo "after +${t}s png=$s"
done