#!/bin/bash
export MSYS_NO_PATHCONV=1
A=/mnt/d/桌面/adb-fastboot/adb.exe
M=/data/adb/modules/starfs

echo "=== version + files ==="
"$A" shell "su -c 'grep -E \"^version\" $M/module.prop; ls -l $M/webroot'" 2>&1 | tr -d '\r'

echo
echo "=== boot-loader.sh info (read-only) ==="
"$A" shell "su -c 'sh $M/webroot/boot-loader.sh info'" 2>&1 | tr -d '\r'

echo
echo "=== powerctl writable check ==="
"$A" shell "su -c 'test -w /sys/powerctl && echo writable || echo not-writable'" 2>&1 | tr -d '\r'

echo
echo "=== gpt plan still works (drives the new + button path) ==="
"$A" shell "su -c 'starfs gpt plan 38 --size 16G 2>&1 | tail -6'" 2>&1 | tr -d '\r'
echo "=== DONE ==="
