#!/bin/bash
# 抓当前屏幕：oem screenshot(读 0xEA600000 像素) -> get_staged -> PNG（Git Bash 版）
F="/d/桌面/adb-fastboot/fastboot.exe"
RAW="C:/ios26/screen-now.raw"
RAWL="/c/ios26/screen-now.raw"
PNG="/c/ios26/screen-now.png"
export MSYS_NO_PATHCONV=1
echo "=== device ==="
timeout 10 "$F" devices 2>&1 | tr -d '\r'
echo "=== oem screenshot (stage 0xEA600000) ==="
timeout 60 "$F" -s xnuloader oem screenshot 2>&1 | tr -d '\r' | tail -3
echo "=== get_staged -> raw ==="
rm -f "$RAWL"
timeout 120 "$F" -s xnuloader get_staged "$RAW" 2>&1 | tr -d '\r' | tail -3
sz=$(stat -c%s "$RAWL" 2>/dev/null || echo 0)
echo "raw size=$sz (expect 18432000)"
if [ "$sz" -ge 18432000 ]; then
  echo "=== convert to PNG (step 2) ==="
  python /d/桌面/star26-deps/scripts/fb2png.py "$RAWL" "$PNG" 2 2>&1
  ls -l "$PNG"
else
  echo "RAW INCOMPLETE, skip convert"
fi
