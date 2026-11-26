#!/bin/bash
A=/d/桌面/adb-fastboot/adb.exe
echo "=== device state ==="
"$A" shell getprop ro.boot.bootloader 2>&1 | tr -d '\r' | head -1
"$A" shell getprop sys.boot_completed 2>&1 | tr -d '\r' | head -1
echo "=== uptime (证明刚重启) ==="
"$A" shell cat /proc/uptime 2>&1 | tr -d '\r' | head -1
echo "=== pstore / ramoops 目录 ==="
"$A" shell "ls -la /sys/fs/pstore/ 2>/dev/null; ls -la /proc/last_kmsg 2>/dev/null" 2>&1 | tr -d '\r' | head -40
echo "=== dmesg-ramoops / console-ramoops ==="
"$A" shell "ls /sys/fs/pstore/*ramoops* 2>/dev/null" 2>&1 | tr -d '\r'
