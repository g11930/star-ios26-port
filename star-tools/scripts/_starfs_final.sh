#!/bin/bash
# Final on-device sanity check after deploying 1.2.  Read-only.
export MSYS_NO_PATHCONV=1
A=/mnt/d/桌面/adb-fastboot/adb.exe

echo "=== module.prop ==="
"$A" shell "su -c 'head -4 /data/adb/modules/starfs/module.prop'" 2>&1 | tr -d '\r'

echo
echo "=== gpt list --tsv (3 lines) ==="
"$A" shell "su -c 'starfs gpt list --tsv | tail -3'" 2>&1 | tr -d '\r'

echo
echo "=== plan darwin 16G (unchanged, must be OK) ==="
"$A" shell "su -c 'starfs gpt plan 38 --size 16G'" 2>&1 | tr -d '\r' | tail -5

echo
echo "=== webui files ==="
"$A" shell "su -c 'ls -la /data/adb/modules/starfs/webroot/'" 2>&1 | tr -d '\r'

echo
echo "=== help text mentions gpt ==="
"$A" shell "su -c 'starfs 2>&1 | grep -c gpt'" 2>&1 | tr -d '\r'
echo "=== DONE ==="
