#!/bin/bash
export MSYS_NO_PATHCONV=1
A=/mnt/d/桌面/adb-fastboot/adb.exe
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
echo "=== adb devices ==="
"$A" devices 2>&1 | tr -d '\r'
echo "=== fastboot product (default) ==="
timeout 8 "$F" getvar product 2>&1 | tr -d '\r' | head -3
echo "=== fastboot -s xnuloader product ==="
timeout 8 "$F" -s xnuloader getvar product 2>&1 | tr -d '\r' | head -3
echo "=== fastboot -s xnuloader result ==="
timeout 8 "$F" -s xnuloader getvar result 2>&1 | tr -d '\r' | head -3
