#!/bin/bash
A=/mnt/d/桌面/adb-fastboot/adb.exe
$A wait-for-device
echo "=== devices ==="; $A devices | head -3
echo "=== touch dmesg ==="
$A shell "dmesg | grep -iE 'fts|focal|touch|tp_' | tail -40" 2>&1 | tail -45