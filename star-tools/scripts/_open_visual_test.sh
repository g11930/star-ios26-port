#!/bin/bash
export MSYS_NO_PATHCONV=1
A=/mnt/d/桌面/adb-fastboot/adb.exe

cp "/mnt/d/桌面/star26-deps/module/starfs/build/webroot/open-dir.sh" /mnt/c/ios26/open-dir.sh
"$A" push "C:/ios26/open-dir.sh" /data/local/tmp/ 2>&1 | tr -d '\r' | tail -1

echo "=== list after fix ==="
"$A" shell "su -c 'sh /data/local/tmp/open-dir.sh list /sdcard/Download'" 2>&1 | tr -d '\r'

echo
echo "=== open MT OpenFileActivity on Download ==="
"$A" shell "su -c 'sh /data/local/tmp/open-dir.sh open /sdcard/Download bin.mt.plus.canary/bin.mt.plus.OpenFileActivity'" 2>&1 | tr -d '\r'
sleep 4
"$A" shell "screencap -p /sdcard/o_mt.png" 2>&1 | tr -d '\r' | grep -v Warning | grep -v display | head -2
"$A" pull /sdcard/o_mt.png C:/ios26/o_mt.png 2>&1 | tr -d '\r' | tail -1

echo
echo "=== open MIUI FileExplorerTabActivity ==="
"$A" shell "su -c 'sh /data/local/tmp/open-dir.sh open /sdcard/Download com.android.fileexplorer/.FileExplorerTabActivity'" 2>&1 | tr -d '\r'
sleep 4
"$A" shell "screencap -p /sdcard/o_miui.png" 2>&1 | tr -d '\r' | grep -v Warning | grep -v display | head -2
"$A" pull /sdcard/o_miui.png C:/ios26/o_miui.png 2>&1 | tr -d '\r' | tail -1
echo "=== DONE ==="
