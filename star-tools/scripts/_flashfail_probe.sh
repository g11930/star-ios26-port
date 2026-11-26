#!/bin/bash
export MSYS_NO_PATHCONV=1
A=/mnt/d/桌面/adb-fastboot/adb.exe
F=/mnt/d/桌面/adb-fastboot/fastboot.exe

echo "=== adb ==="
"$A" devices 2>&1 | tr -d '\r'
echo "=== fastboot ==="
timeout 6 "$F" getvar product 2>&1 | tr -d '\r' | head -2

echo
echo "=== top activity ==="
"$A" shell "dumpsys activity activities 2>/dev/null | grep -E 'topResumedActivity' | head -4" 2>&1 | tr -d '\r'

echo
echo "=== suspicious flashing apps ==="
"$A" shell "pm list packages 2>/dev/null | grep -i -E 'mtb|flash|twrp|odin|xnu|loader|ios|star'" 2>&1 | tr -d '\r'

echo
echo "=== GPT still valid? (sda headers) ==="
"$A" shell "su -c 'dd if=/dev/block/sda bs=512 count=1 2>/dev/null | strings | head -3; echo ---; dd if=/dev/block/sda bs=512 skip=1 count=1 2>/dev/null | strings | head -2'" 2>&1 | tr -d '\r'

echo
echo "=== partition nodes ==="
"$A" shell "su -c 'ls /dev/block/sda* 2>/dev/null | wc -l; cat /proc/partitions | grep sda | head -3'" 2>&1 | tr -d '\r'
echo "=== DONE ==="
