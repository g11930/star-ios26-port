#!/bin/bash
A=/mnt/d/桌面/adb-fastboot/adb.exe
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
IMG=C:/ios26/s201-boot.img
$A reboot bootloader > /dev/null 2>&1
for i in $(seq 1 25); do sleep 2; $F devices | grep -q "	fastboot" && break; done
echo "fb: $($F devices | head -1)"
$F boot "$IMG" 2>&1 | tail -2 || { echo refused; exit 0; }
for i in $(seq 1 7); do
  sleep 60
  $F -s xnuloader oem log > /dev/null 2>&1
  $F -s xnuloader get_staged "C:/ios26/s201b.bin" > /dev/null 2>&1
  strings -n 5 /mnt/c/ios26/s201b.bin > /tmp/s201b.txt
  echo "T+$((i*60))s lines=$(wc -l < /tmp/s201b.txt) tl=$(grep -ac 'tl: v ' /tmp/s201b.txt) sb=$(grep -ac 'SpringBoard 33' /tmp/s201b.txt) last=$(grep -a -oE '2025-12-[0-9]+ [0-9:.]+\+0800' /tmp/s201b.txt | tail -1)"
  [ "$(grep -ac 'tl: v ' /tmp/s201b.txt)" -gt 0 ] && break
done