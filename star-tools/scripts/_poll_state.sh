#!/bin/bash
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
A=/mnt/d/桌面/adb-fastboot/adb.exe
for i in $(seq 1 30); do
  sleep 6
  fb=$($F devices | head -1)
  adb=$($A devices | awk 'NR==2{print $1}')
  echo "t=${i}x6s fastboot=[${fb}] adb=[${adb}]"
  if [ -n "$fb" ] || [ -n "$adb" ]; then break; fi
done