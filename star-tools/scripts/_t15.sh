#!/bin/bash
A=/mnt/d/桌面/adb-fastboot/adb.exe
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
$F -s xnuloader oem stop > /dev/null 2>&1
echo "stopped; waiting android"
for i in $(seq 1 80); do sleep 3; $A devices | grep -q "	device" && { echo "android up at $((i*3))s"; break; }; done
$A devices | head -3