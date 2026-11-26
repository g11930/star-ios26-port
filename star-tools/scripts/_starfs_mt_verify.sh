#!/bin/bash
export MSYS_NO_PATHCONV=1
A=/mnt/d/桌面/adb-fastboot/adb.exe
M=/data/adb/modules/starfs

echo "=== module tree ==="
"$A" shell "su -c 'ls -la $M $M/webroot'" 2>&1 | tr -d '\r'

echo
echo "=== version ==="
"$A" shell "su -c 'grep -E \"^version\" $M/module.prop'" 2>&1 | tr -d '\r'

echo
echo "=== index.html carries the new code? ==="
"$A" shell "su -c 'grep -c \"open-dir.sh\" $M/webroot/index.html; grep -c \"moduleInfo\" $M/webroot/index.html'" 2>&1 | tr -d '\r'

echo
echo "=== open-dir.sh list from the installed path ==="
"$A" shell "su -c 'sh $M/webroot/open-dir.sh list /sdcard/Download'" 2>&1 | tr -d '\r'

echo
echo "=== open-dir.sh ls ==="
"$A" shell "su -c 'sh $M/webroot/open-dir.sh ls /sdcard/Download'" 2>&1 | tr -d '\r' | head -12

echo
echo "=== simulate the exact WebUI command shape (single arg exec) ==="
"$A" shell "su -c \"sh '$M/webroot/starfs-run.sh' root\"" 2>&1 | tr -d '\r' | head -6
echo "=== DONE ==="
