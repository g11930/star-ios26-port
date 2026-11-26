#!/bin/bash
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
for k in 1 2 3 4 5 6; do
  sleep 60
  $F -s xnuloader oem screenshot > /dev/null 2>&1
  $F -s xnuloader get_staged "C:/ios26/s212-frame.raw" > /dev/null 2>&1
  python3 /mnt/d/桌面/star26-deps/scripts/fb2png.py /mnt/c/ios26/s212-frame.raw /mnt/c/ios26/s212-frame.png > /dev/null 2>&1
  s=$(stat -c %s /mnt/c/ios26/s212-frame.png)
  echo "T+$((k*60))s png=$s"
  [ "$s" -gt 600000 ] && { cp /mnt/c/ios26/s212-frame.png /mnt/c/ios26/s212-desktop.png; echo DESKTOP; break; }
done
$F -s xnuloader oem log > /dev/null 2>&1
$F -s xnuloader get_staged "C:/ios26/s212log.bin" > /dev/null 2>&1
strings -n 5 /mnt/c/ios26/s212log.bin > /tmp/s212log.txt
echo "lines=$(wc -l < /tmp/s212log.txt) stats=$(grep -ac 'frames in' /tmp/s212log.txt) sb=$(grep -ac 'SpringBoard 33' /tmp/s212log.txt)"
grep -a 'frames in' /tmp/s212log.txt | tail -6