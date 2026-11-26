#!/bin/bash
export MSYS_NO_PATHCONV=1
A=/mnt/d/桌面/adb-fastboot/adb.exe
SRC=/mnt/c/ios26/open-dir.sh

cp "/mnt/d/桌面/star26-deps/module/starfs/build/webroot/open-dir.sh" "$SRC"
echo "=== push ==="
"$A" push "C:/ios26/open-dir.sh" /data/local/tmp/ 2>&1 | tr -d '\r' | tail -1

echo
echo "=== list /sdcard/Download ==="
"$A" shell "su -c 'sh /data/local/tmp/open-dir.sh list /sdcard/Download'" 2>&1 | tr -d '\r'

echo
echo "=== list /data/local/tmp ==="
"$A" shell "su -c 'sh /data/local/tmp/open-dir.sh list /data/local/tmp'" 2>&1 | tr -d '\r'

echo
echo "=== ls /sdcard/Download (starfs only) ==="
"$A" shell "su -c 'sh /data/local/tmp/open-dir.sh ls /sdcard/Download' 2>&1 | grep -i starfs" 2>&1 | tr -d '\r'

echo
echo "=== error path: bad component ==="
"$A" shell "su -c 'sh /data/local/tmp/open-dir.sh open /sdcard/Download nope/none'" 2>&1 | tr -d '\r'

echo
echo "=== error path: missing dir ==="
"$A" shell "su -c 'sh /data/local/tmp/open-dir.sh ls /sdcard/NoSuchDir'" 2>&1 | tr -d '\r'
echo "=== DONE ==="
