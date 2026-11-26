#!/bin/bash
export MSYS_NO_PATHCONV=1
A=/mnt/d/桌面/adb-fastboot/adb.exe
F=/mnt/d/桌面/adb-fastboot/fastboot.exe

echo "=== restart adb server ==="
"$A" kill-server >/dev/null 2>&1
sleep 1
"$A" start-server >/dev/null 2>&1
sleep 2

echo "=== adb devices ==="
"$A" devices 2>&1 | tr -d '\r'

echo "=== fastboot (any) ==="
timeout 8 "$F" getvar product 2>&1 | tr -d '\r' | head -3

echo "=== fastboot -s xnuloader ==="
timeout 8 "$F" -s xnuloader getvar product 2>&1 | tr -d '\r' | head -3

echo "=== windows pnp (via powershell.exe) ==="
powershell.exe -NoProfile -Command "Get-PnpDevice -PresentOnly -Class USB | Where-Object { \$_.InstanceId -match 'VID_18D1|VID_2717' } | Select-Object -ExpandProperty InstanceId" 2>&1 | tr -d '\r' | head -8
