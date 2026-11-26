#!/bin/bash
# s201 刷入 = s199 + cmdline 追加 fb_diff=1（内核 6db65880 未动）。设备现在可能停在 loader（xnuloader）或 Android，两种都处理：
#   loader  -> fastboot reboot 冷复位回 Android
#   Android -> adb reboot bootloader -> fastboot boot s201-boot.img
set -u
A=/mnt/d/桌面/adb-fastboot/adb.exe
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
IMG=C:/ios26/s201-boot.img

echo "=== [0] where are we ==="
"$A" devices 2>&1 | tr -d '\r'
timeout 8 "$F" devices 2>&1 | tr -d '\r'

if timeout 8 "$F" devices 2>&1 | tr -d '\r' | grep -q 'xnuloader'; then
  echo "=== [0a] in loader -> cold reset back to Android ==="
  timeout 20 "$F" -s xnuloader reboot 2>&1 | tr -d '\r' | tail -2
  sleep 5
fi

echo "=== [1] wait for Android adb ==="
ok=0
for i in $(seq 1 60); do
  n=$("$A" devices 2>&1 | tr -d '\r' | grep -c 'device$' || true)
  if [ "$n" != "0" ]; then echo "  adb up after $((i*2))s"; ok=1; break; fi
  sleep 2
done
"$A" devices 2>&1 | tr -d '\r'
if [ "$ok" != "1" ]; then echo "NO ANDROID ADB -- stop here"; exit 1; fi

echo "=== [2] reboot to bootloader ==="
"$A" reboot bootloader 2>&1 | tr -d '\r'

echo "=== [3] wait for fastboot ==="
ok=0
for i in $(seq 1 40); do
  p=$(timeout 8 "$F" getvar product 2>&1 | tr -d '\r' | grep -m1 'product:' || true)
  if [ -n "$p" ]; then echo "  bootloader up after ${i}: $p"; ok=1; break; fi
  sleep 2
done
if [ "$ok" != "1" ]; then echo "NO BOOTLOADER"; exit 1; fi

echo "=== [4] boot s201 ==="
timeout 200 "$F" boot "$IMG" 2>&1 | tr -d '\r' | tail -8

echo "=== [5] wait for loader (xnuloader) ==="
for i in $(seq 1 45); do
  d=$(timeout 8 "$F" devices 2>&1 | tr -d '\r' | grep -c 'xnuloader' || true)
  if [ "$d" != "0" ]; then echo "  loader up after $((i*2))s"; break; fi
  sleep 2
done
timeout 8 "$F" devices 2>&1 | tr -d '\r'
echo "=== done ==="
