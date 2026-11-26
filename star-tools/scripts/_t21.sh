#!/bin/bash
A=/mnt/d/桌面/adb-fastboot/adb.exe
echo "=== devices ==="; $A devices | head -3
echo "=== fts dmesg ==="
timeout 90 $A shell "dmesg | grep -iE 'fts_|focaltech|st_fts|touchpanel|Chip' | tail -40" 2>&1 | tail -42
echo "=== tp gpio ==="
timeout 40 $A shell "cat /sys/kernel/debug/gpio 2>/dev/null | grep -iE 'tp|avdd|reset|132|154' | head -20" 2>&1 | head -22