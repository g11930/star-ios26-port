#!/bin/bash
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
for c in "oem boot C:/ios26/s182-boot.img" "oem boot" "oem start" "oem run"; do
  echo "--- $c"
  timeout 8 $F -s xnuloader $c 2>&1 | tail -2
  sleep 2
  echo "dev: $($F devices | head -1)"
done