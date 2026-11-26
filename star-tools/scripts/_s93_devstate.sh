#!/bin/bash
export MSYS_NO_PATHCONV=1
A=/mnt/d/桌面/adb-fastboot/adb.exe
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
echo "=== adb kill-server / start-server ==="
"$A" kill-server >/dev/null 2>&1
"$A" start-server 2>&1 | tr -d '\r'
echo "=== adb devices (3 tries) ==="
for i in 1 2 3; do
	"$A" devices 2>&1 | tr -d '\r'
	sleep 2
done
echo "=== fastboot devices ==="
timeout 8 "$F" devices 2>&1 | tr -d '\r'
echo "=== fastboot getvar product ==="
timeout 8 "$F" getvar product 2>&1 | tr -d '\r' | head -5
echo "=== USB VID/PID via PowerShell (Windows side) ==="
powershell.exe -NoProfile -Command "Get-PnpDevice -PresentOnly | Where-Object { \$_.InstanceId -match 'VID_18D1|VID_2717' } | Select-Object Status,FriendlyName,InstanceId | Format-List" 2>&1 | tr -d '\r' | head -40
