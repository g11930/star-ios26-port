#!/bin/bash
A=/mnt/d/桌面/adb-fastboot/adb.exe
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
echo "--- reboot"
timeout 15 $F -s xnuloader reboot 2>&1 | tail -2
sleep 20
echo "fb: $($F devices | head -1)  adb: $($A devices | tail -1)"
echo "--- oem stop again"
timeout 15 $F -s xnuloader oem stop 2>&1 | tail -1
for i in $(seq 1 20); do sleep 6; st=$($A devices | awk 'NR==2{print $2}'); echo "t=$((i*6))s adb=$st fb=[$($F devices | head -1)]"; [ -n "$st" ] && break; done