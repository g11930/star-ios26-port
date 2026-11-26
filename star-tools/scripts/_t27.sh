#!/bin/bash
A=/mnt/d/桌面/adb-fastboot/adb.exe
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
echo "adb: $($A devices | awk 'NR==2{print $2}')  fb: $($F devices | head -1)"