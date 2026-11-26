#!/bin/bash
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
start=$(date +%s)
for i in $(seq 1 16); do
  sleep 20
  $F -s xnuloader oem screenshot > /dev/null 2>&1
  $F -s xnuloader get_staged "C:/ios26/t5-frame.raw" > /dev/null 2>&1
  b=$(python3 /mnt/d/桌面/star26-deps/scripts/fb2png.py /mnt/c/ios26/t5-frame.raw /mnt/c/ios26/t5-frame.png 2>&1 | grep -oE '[0-9]+ bytes' | head -1 | grep -oE '[0-9]+')
  now=$(date +%s)
  echo "T+$((now-start)) s frame ${b:-?}"
  if [ -n "$b" ] && [ "$b" -gt 100000 ] && [ "$b" -lt 200000 ]; then
    echo "DESKTOP-LIKE at T+$((now-start)) s (size $b)"
    cp /mnt/c/ios26/t5-frame.png /mnt/c/ios26/second-boot-desktop.png
    break
  fi
done