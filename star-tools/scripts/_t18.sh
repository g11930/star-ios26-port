#!/bin/bash
A=/mnt/d/桌面/adb-fastboot/adb.exe
$A devices | head -3
echo "=== fts dmesg ==="
timeout 60 $A shell "dmesg | grep -iE 'fts_|focaltech|st_fts|touchpanel' | tail -30" 2>&1 | tail -32
echo "=== gpio 132/154 state ==="
timeout 30 $A shell "cat /sys/kernel/debug/gpio | grep -E 'gpio-132|gpio-154|tp_|avdd'" 2>&1 | head -12