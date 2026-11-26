#!/bin/bash
A=/mnt/d/桌面/adb-fastboot/adb.exe
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
IMG=C:/ios26/s200-boot.img
$A reboot bootloader > /dev/null 2>&1
for i in $(seq 1 25); do sleep 2; $F devices | grep -q "	fastboot" && break; done
$F devices | head -1
$F boot "$IMG" 2>&1 | tail -2 || { echo refused; exit 0; }
for i in $(seq 1 8); do
  sleep 60
  $F -s xnuloader oem log > /dev/null 2>&1
  $F -s xnuloader get_staged "C:/ios26/s200a.bin" > /dev/null 2>&1
  strings -n 5 /mnt/c/ios26/s200a.bin > /tmp/s200a.txt
  echo "T+$((i*60))s lines=$(wc -l < /tmp/s200a.txt) last=$(grep -a -oE '2025-12-[0-9]+ [0-9:.]+\+0800' /tmp/s200a.txt | tail -1)"
  grep -aq 'PANIC' /tmp/s200a.txt && { echo PANIC; grep -a 'PANIC' /tmp/s200a.txt | head -2; break; }
  grep -aq 'SpringBoard 33' /tmp/s200a.txt && break
done
$F -s xnuloader oem screenshot > /dev/null 2>&1
$F -s xnuloader get_staged "C:/ios26/s200-frame.raw" > /dev/null 2>&1
python3 /mnt/d/桌面/star26-deps/scripts/fb2png.py /mnt/c/ios26/s200-frame.raw /mnt/c/ios26/s200-frame.png > /dev/null 2>&1
ls -l /mnt/c/ios26/s200-frame.png