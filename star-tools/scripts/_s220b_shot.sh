#!/bin/bash
# s212 专用截图：oem screenshot -> get_staged -> PNG（独立文件名，不覆盖旧证据）
F="/d/桌面/adb-fastboot/fastboot.exe"
RAW="C:/ios26/s220b-screen.raw"
RAWL="/c/ios26/s220b-screen.raw"
export MSYS_NO_PATHCONV=1
echo "=== device ==="
timeout 12 "$F" devices 2>&1 | tr -d '\r'
echo "=== oem screenshot ==="
timeout 60 "$F" -s xnuloader oem screenshot 2>&1 | tr -d '\r' | tail -3
echo "=== get_staged -> raw ==="
rm -f "$RAWL"
timeout 120 "$F" -s xnuloader get_staged "$RAW" 2>&1 | tr -d '\r' | tail -3
sz=$(stat -c%s "$RAWL" 2>/dev/null || echo 0)
echo "raw size=$sz (expect 18432000)"
if [ "$sz" -ge 18432000 ]; then
  echo "=== convert (step2 + full) ==="
  wsl.exe -d Ubuntu-24.04 bash -c "cd /mnt/d/桌面/star26-deps/scripts && python3 fb2png.py /mnt/c/ios26/s220b-screen.raw /mnt/c/ios26/s220b-screen.png 2 && python3 fb2png.py /mnt/c/ios26/s220b-screen.raw /mnt/c/ios26/s220b-screen-full.png 1" 2>&1 | tr -d '\r'
  ls -la /c/ios26/s220b-screen*.png
else
  echo "RAW INCOMPLETE, skip convert"
fi
