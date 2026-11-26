#!/bin/bash
A=/mnt/d/桌面/adb-fastboot/adb.exe
M=/data/adb/modules/starfs
echo "=== device module.prop ==="
"$A" shell "su -c 'cat $M/module.prop'" 2>&1 | tr -d '\r' | head -5
echo
echo "=== page gate on device (must hit verdict  OK / NOOP / REFUSED) ==="
"$A" shell "su -c \"grep -n 'verdict  \' $M/webroot/index.html\"" 2>&1 | tr -d '\r'
echo
echo "=== page no longer parses prose ==="
"$A" shell "su -c \"grep -c 'OK to write' $M/webroot/index.html\"" 2>&1 | tr -d '\r'
echo "(0 = 旧判定已消失)"
echo
echo "=== open-dir default dir present on device ==="
"$A" shell "su -c \"grep -n 'DIR_DEFAULT' $M/webroot/open-dir.sh\"" 2>&1 | tr -d '\r'
echo
echo "=== tsv purity re-check on device ==="
"$A" shell "su -c \"sh $M/webroot/starfs-run.sh gpt list --tsv\"" 2>&1 | tr -d '\r' | head -2
