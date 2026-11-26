#!/bin/bash
A=/mnt/d/桌面/adb-fastboot/adb.exe
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
for i in $(seq 1 40); do
  sleep 4
  f=$($F devices 2>/dev/null | head -1)
  a=$($A devices | awk 'NR==2{print $2}')
  [ -n "$f$a" ] && { echo "up t=$((i*4))s fb=[$f] adb=$a"; exit 0; }
done
echo "dark 160s"