#!/bin/bash
A=/mnt/d/桌面/adb-fastboot/adb.exe
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
IMG=${IMG:-C:/ios26/s187-boot.img}
$F -s xnuloader oem stop > /dev/null 2>&1
echo "waiting android"
for i in $(seq 1 70); do sleep 3; $A devices | grep -q "	device" && break; done
$A devices | head -2
$A reboot bootloader > /dev/null 2>&1
for i in $(seq 1 25); do sleep 2; $F devices | grep -q "	fastboot" && break; done
$F devices | head -1
$F boot "$IMG" 2>&1 | tail -2 || { echo refused; exit 0; }
for i in $(seq 1 10); do
  sleep 30
  $F -s xnuloader oem log > /dev/null 2>&1
  $F -s xnuloader get_staged "C:/ios26/s187a.bin" > /dev/null 2>&1
  strings -n 5 /mnt/c/ios26/s187a.bin > /tmp/s187a.txt
  echo "T+$((i*30)) thumbs=$(grep -ac 'thumb [0-9]*:' /tmp/s187a.txt) matched=$(grep -ac 'sync matched' /tmp/s187a.txt) last=$(grep -a -oE '2025-12-10 [0-9:.]+\+0800' /tmp/s187a.txt | tail -1)"
  if grep -aq 'thumb [0-9]*:' /tmp/s187a.txt; then break; fi
done
echo "=== thumb headers ==="; grep -a 'thumb [0-9]*:' /tmp/s187a.txt | head -6
echo "=== sync lines ==="; grep -a 'sync matched' /tmp/s187a.txt | head -4