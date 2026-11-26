#!/bin/bash
A=/mnt/d/桌面/adb-fastboot/adb.exe
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
echo "--- reboot"; timeout 10 $F -s xnuloader reboot 2>&1 | tail -1
for i in $(seq 1 12); do sleep 5; a=$($A devices | awk 'NR==2{print $2}'); [ -n "$a" ] && { echo "adb up ${i}x5s"; exit 0; }; done
echo "--- oem stop"; timeout 10 $F -s xnuloader oem stop 2>&1 | tail -1
for i in $(seq 1 24); do sleep 5; a=$($A devices | awk 'NR==2{print $2}'); f=$($F devices | head -1); echo "t=$((i*5))s adb=$a fb=[$f]"; [ -n "$a" ] && exit 0; done