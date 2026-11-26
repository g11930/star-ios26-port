#!/bin/bash
A=/mnt/d/桌面/adb-fastboot/adb.exe
M=/data/adb/modules/starfs
echo "=== plan 38 --size 20G (verbatim, tabs shown as ^I) ==="
"$A" shell "su -c \"sh $M/webroot/starfs-run.sh gpt plan 38 --size 20G\"" 2>&1 | tr -d '\r' | cat -A | sed -n '1,30p'
echo
echo "=== plan 36 --size 2G (must be REFUSED) ==="
"$A" shell "su -c \"sh $M/webroot/starfs-run.sh gpt plan 36 --size 2G\"" 2>&1 | tr -d '\r' | tail -12
