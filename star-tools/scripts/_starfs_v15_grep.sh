#!/bin/bash
A=/mnt/d/桌面/adb-fastboot/adb.exe
M=/data/adb/modules/starfs
echo "=== 页面里 verdict 判定所在行 ==="
"$A" shell "su -c \"grep -n verdict $M/webroot/index.html\"" 2>&1 | tr -d '\r'
echo
echo "=== OK to write 出现的上下文（应只剩注释）==="
"$A" shell "su -c \"grep -n -B1 -A1 'OK to write' $M/webroot/index.html\"" 2>&1 | tr -d '\r'
