#!/bin/bash
# 截取当前屏幕：oem screenshot 后 get_staged（Windows 路径）。
set -u
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
echo "=== screenshot ==="
timeout 30 "$F" -s xnuloader oem screenshot 2>&1 | tr -d '\r' | tail -3
sleep 2
echo "=== get_staged ==="
timeout 60 "$F" -s xnuloader get_staged C:/ios26/s205-shot.bin 2>&1 | tr -d '\r' | tail -2
ls -la /mnt/c/ios26/s205-shot.bin 2>/dev/null
file /mnt/c/ios26/s205-shot.bin 2>/dev/null
echo "=== done ==="
