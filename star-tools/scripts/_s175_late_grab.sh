#!/bin/bash
# grab a LATE snapshot of the still-running s175 loader + kernel log
export MSYS_NO_PATHCONV=1
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
p=$(timeout 8 "$F" -s xnuloader getvar product 2>&1 | tr -d '\r' | grep -i product: | head -1)
echo "loader product: $p"
case "$p" in *xnuloader*) ;; *) echo "loader not present, abort"; exit 1 ;; esac

echo "=== kernel log first (shared staged buffer) ==="
rm -f /mnt/c/ios26/s175-late-log.bin
timeout 30 "$F" -s xnuloader oem log >/dev/null 2>&1
timeout 45 "$F" -s xnuloader get_staged "C:/ios26/s175-late-log.bin" 2>&1 | tr -d '\r' | tail -1

echo "=== screenshot second ==="
rm -f /mnt/c/ios26/s175-late-frame.raw
timeout 30 "$F" -s xnuloader oem screenshot >/dev/null 2>&1
timeout 45 "$F" -s xnuloader get_staged "C:/ios26/s175-late-frame.raw" 2>&1 | tr -d '\r' | tail -1

echo "=== convert ==="
cd /mnt/d/桌面/star26-deps/scripts
python3 raw2png.py /mnt/c/ios26/s175-late-frame.raw 2>&1 | head -2
python3 raw2png.py /mnt/c/ios26/s173c-frame.raw 2>&1 | head -2
python3 raw2png.py /mnt/c/ios26/s174c-frame.raw 2>&1 | head -2
ls -la /mnt/c/ios26/s175-late-frame.png /mnt/c/ios26/s173c-frame.png /mnt/c/ios26/s174c-frame.png 2>/dev/null
