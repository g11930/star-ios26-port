#!/bin/bash
A=/mnt/d/桌面/adb-fastboot/adb.exe
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
$F -s xnuloader reboot > /dev/null 2>&1
echo "reboot sent; waiting for android"
for i in $(seq 1 40); do sleep 3; $A devices | grep -q device && break; done
$A devices | head -3
$A reboot bootloader
for i in $(seq 1 25); do sleep 2; $F devices | grep -q fastboot && break; done
$F devices
$F boot "C:/ios26/s182-boot.img" || exit 0
start=$(date +%s)
for i in $(seq 1 16); do
  sleep 30
  $F -s xnuloader oem screenshot > /dev/null 2>&1
  $F -s xnuloader get_staged "C:/ios26/t2-frame.raw" > /dev/null 2>&1
  b=$(python3 /mnt/d/桌面/star26-deps/scripts/fb2png.py /mnt/c/ios26/t2-frame.raw /mnt/c/ios26/t2-frame.png 2>&1 | grep -oE '[0-9]+ bytes' | head -1 | grep -oE '[0-9]+')
  now=$(date +%s)
  echo "T+$((now-start)) s frame $b bytes"
  if [ -n "$b" ] && [ "$b" -gt 100000 ]; then echo "DESKTOP at T+$((now-start)) s"; break; fi
done
</>
