#!/bin/bash
A=/mnt/d/桌面/adb-fastboot/adb.exe
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
IMG=C:/ios26/s208-boot.img
$A reboot bootloader > /dev/null 2>&1
for i in $(seq 1 30); do sleep 2; $F devices | grep -q "	fastboot" && break; done
echo "abl: $($F devices | head -1)"
timeout 20 $F boot "$IMG" 2>&1 | tail -2
for i in $(seq 1 20); do sleep 3; $F devices 2>/dev/null | grep -q xnuloader && { echo "loader up t=$((i*3))s"; break; }; done
for k in 1 2 3 4 5; do
  sleep 90
  $F -s xnuloader oem log > /dev/null 2>&1
  $F -s xnuloader get_staged "C:/ios26/s208c.bin" > /dev/null 2>&1
  strings -n 5 /mnt/c/ios26/s208c.bin > /tmp/s208c.txt
  n=$(grep -ac 'frames in' /tmp/s208c.txt)
  echo "T+$((k*90))s lines=$(wc -l < /tmp/s208c.txt) stats=$n sb=$(grep -ac 'SpringBoard 33' /tmp/s208c.txt) panic=$(grep -ac PANIC /tmp/s208c.txt) last=$(grep -a -oE '2025-12-[0-9]+ [0-9:.]+\+0800' /tmp/s208c.txt | tail -1)"
  [ "$n" -gt 0 ] && break
done
echo "=== stats ==="
grep -a 'frames in' /tmp/s208c.txt | tail -8