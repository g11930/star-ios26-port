#!/bin/bash
# Exercise every script in the freshly installed module and check the things that only
# break at runtime: the report file, the idempotent copies, the WebUI proxy, and the
# SELinux context of webroot (the KSU installer normally sets that; this phone has to
# install by hand because ksud rejects the zip with a UAPI mismatch).
export MSYS_NO_PATHCONV=1
A=/mnt/d/桌面/adb-fastboot/adb.exe

echo "=== 1. starfs usage (real APFS read from block device) ==="
"$A" shell "su -c 'starfs usage'" 2>&1 | tr -d '\r' | head -30

echo
echo "=== 2. action.sh (report + dialog summary) ==="
"$A" shell "su -c 'sh /data/adb/modules/starfs/action.sh'" 2>&1 | tr -d '\r'

echo
echo "=== 3. report file on sdcard ==="
"$A" shell "su -c 'ls -la /sdcard/Download/starfs-report.txt; head -6 /sdcard/Download/starfs-report.txt'" 2>&1 | tr -d '\r'

echo
echo "=== 4. post-fs-data.sh idempotent (expect rc=0, no output) ==="
"$A" shell "su -c 'sh /data/adb/modules/starfs/post-fs-data.sh; echo rc=\$?'" 2>&1 | tr -d '\r'

echo
echo "=== 5. service.sh idempotent ==="
"$A" shell "su -c 'sh /data/adb/modules/starfs/service.sh; echo rc=\$?'" 2>&1 | tr -d '\r'

echo
echo "=== 6. webroot proxy ==="
"$A" shell "su -c 'sh /data/adb/modules/starfs/webroot/starfs-run.sh root'" 2>&1 | tr -d '\r'

echo
echo "=== 7. webroot present + SELinux context ==="
"$A" shell "su -c 'ls -laZ /data/adb/modules/starfs/webroot'" 2>&1 | tr -d '\r'

echo
echo "=== 8. context of other installed modules for comparison ==="
"$A" shell "su -c 'ls -1 /data/adb/modules/; echo ---; for d in /data/adb/modules/*/; do echo \$d; ls -dZ \$d 2>/dev/null; done'" 2>&1 | tr -d '\r'

echo
echo "=== 9. manager-visible module state ==="
"$A" shell "su -c 'cat /data/adb/modules/starfs/module.prop; echo ---; ls /data/adb/modules/starfs/'" 2>&1 | tr -d '\r'
echo "=== DONE ==="
