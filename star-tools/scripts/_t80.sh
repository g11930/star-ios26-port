#!/bin/bash
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
A=/mnt/d/桌面/adb-fastboot/adb.exe
echo "fb: $($F devices | head -1) adb: $($A devices | awk 'NR==2{print $2}')"
ls -l --time-style=+%T /mnt/c/ios26/s212-boot.img 2>/dev/null | awk '{print $5,$6}'
[ -f /mnt/c/ios26/s212-frame.png ] && stat -c %s /mnt/c/ios26/s212-frame.png