#!/bin/bash
# grab fresh kernel log + screenshot from the still-running s175, for CPU/GPU/icon diagnosis
export MSYS_NO_PATHCONV=1
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
p=$(timeout 8 "$F" -s xnuloader getvar product 2>&1 | tr -d '\r' | grep -i product: | head -1)
echo "loader: $p"
case "$p" in *xnuloader*) ;; *) echo "loader not present"; exit 1 ;; esac

rm -f /mnt/c/ios26/s175-cpugpu-log.bin
timeout 30 "$F" -s xnuloader oem log >/dev/null 2>&1
timeout 45 "$F" -s xnuloader get_staged "C:/ios26/s175-cpugpu-log.bin" 2>&1 | tr -d '\r' | tail -1

rm -f /mnt/c/ios26/s175-cpugpu-frame.raw
timeout 30 "$F" -s xnuloader oem screenshot >/dev/null 2>&1
timeout 45 "$F" -s xnuloader get_staged "C:/ios26/s175-cpugpu-frame.raw" 2>&1 | tr -d '\r' | tail -1

ls -la /mnt/c/ios26/s175-cpugpu-log.bin /mnt/c/ios26/s175-cpugpu-frame.raw
