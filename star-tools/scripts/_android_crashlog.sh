#!/bin/bash
A=/mnt/d/桌面/adb-fastboot/adb.exe
echo "=== adb devices ==="
"$A" devices 2>&1 | tr -d '\r'
echo "=== dmesg tail ==="
"$A" shell "dmesg | tail -80" 2>&1 | tr -d '\r' | tail -80
echo "=== logcat -d ==="
"$A" logcat -d -t 150 2>&1 | tr -d '\r' | tail -50
