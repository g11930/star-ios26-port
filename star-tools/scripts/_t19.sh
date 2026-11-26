#!/bin/bash
A=/mnt/d/桌面/adb-fastboot/adb.exe
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
for i in $(seq 1 40); do
  sleep 5
  st=$($A devices | awk 'NR==2{print $2}')
  fb=$($F devices | head -1)
  echo "t=$((i*5))s adb=$st fb=[$fb]"
  [ -n "$st" ] && break
done