#!/bin/bash
# s198 刷入：Android -> bootloader -> fastboot boot s198-boot.img
set -u
A=/mnt/d/桌面/adb-fastboot/adb.exe
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
WIMG=C:/ios26/s198-boot.img

echo "=== [1] device now ==="
"$A" devices 2>&1 | tr -d '\r'

echo "=== [2] reboot to bootloader ==="
"$A" reboot bootloader 2>&1 | tr -d '\r'

echo "=== [3] wait for fastboot ==="
ok=0
for i in $(seq 1 40); do
  p=$(timeout 8 "$F" getvar product 2>&1 | tr -d '\r' | grep -m1 'product:' || true)
  if [ -n "$p" ]; then echo "  bootloader up after ${i}s: $p"; ok=1; break; fi
  sleep 2
done
if [ "$ok" != "1" ]; then echo "NO BOOTLOADER"; exit 1; fi

echo "=== [4] boot s198 ==="
timeout 180 "$F" boot "$WIMG" 2>&1 | tr -d '\r' | tail -8

echo "=== [5] wait for loader (xnuloader) ==="
for i in $(seq 1 45); do
  d=$(timeout 8 "$F" devices 2>&1 | tr -d '\r' | grep -c 'xnuloader' || true)
  if [ "$d" != "0" ]; then echo "  loader up after $((i*2))s"; break; fi
  sleep 2
done
timeout 8 "$F" devices 2>&1 | tr -d '\r'
echo "=== done ==="
