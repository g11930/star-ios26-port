#!/bin/bash
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
for i in 1 2 3 4 5; do
  sleep 60
  $F -s xnuloader oem log > /dev/null 2>&1
  $F -s xnuloader get_staged "C:/ios26/s200b.bin" > /dev/null 2>&1
  strings -n 5 /mnt/c/ios26/s200b.bin > /tmp/s200b.txt
  $F -s xnuloader oem screenshot > /dev/null 2>&1
  $F -s xnuloader get_staged "C:/ios26/s200-frame2.raw" > /dev/null 2>&1
  python3 /mnt/d/桌面/star26-deps/scripts/fb2png.py /mnt/c/ios26/s200-frame2.raw /mnt/c/ios26/s200-frame2.png > /dev/null 2>&1
  cp /mnt/c/ios26/s200-frame2.png "/mnt/c/ios26/s200-$i.png"
  echo "T+$((120+i*60))s lines=$(wc -l < /tmp/s200b.txt) png=$(stat -c %s /mnt/c/ios26/s200-$i.png) sb=$(grep -ac 'SpringBoard 33' /tmp/s200b.txt)"
done