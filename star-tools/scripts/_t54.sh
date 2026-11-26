#!/bin/bash
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
IMG=C:/ios26/s208-boot.img
echo "fb before: $($F devices | head -1)"
timeout 20 $F boot "$IMG" 2>&1 | tail -2
for i in $(seq 1 20); do sleep 3; $F devices | grep -q xnuloader && { echo "loader up t=$((i*3))s"; break; }; done
echo "fb after: $($F devices | head -1)"