#!/bin/bash
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
for c in "oem help" "oem reboot" "reboot bootloader" "reboot"; do
  echo "--- $c"
  $F -s xnuloader $c 2>&1 | head -4
  sleep 3
  echo "devices: $($F devices | head -1)"
done