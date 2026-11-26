#!/bin/bash
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
A=/mnt/d/桌面/adb-fastboot/adb.exe
echo "=== fastboot"
$F devices
echo "=== adb"
$A devices | head -3
echo "=== loader screenshot"
timeout 10 $F -s xnuloader oem screenshot 2>&1 | tail -2