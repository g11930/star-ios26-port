#!/bin/bash
export MSYS_NO_PATHCONV=1
echo "=== PATH has adb-fastboot? ==="
echo "$PATH" | tr ':' '\n' | grep -i 'adb-fastboot' || echo "NOT in PATH"
echo "=== tool absolute paths ==="
ls -la /mnt/d/桌面/adb-fastboot/fastboot.exe /mnt/d/桌面/adb-fastboot/adb.exe
echo "=== target image ==="
ls -la /c/ios26/s93-boot.img
echo "=== adb devices ==="
/mnt/d/桌面/adb-fastboot/adb.exe devices 2>&1
echo "=== fastboot devices ==="
timeout 8 /mnt/d/桌面/adb-fastboot/fastboot.exe devices 2>&1
echo "=== fastboot getvar product ==="
timeout 8 /mnt/d/桌面/adb-fastboot/fastboot.exe getvar product 2>&1 | tr -d '\r' | grep -i 'product:' | head -1 || echo "(no product / not in fastboot)"
