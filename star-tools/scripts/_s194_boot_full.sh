#!/bin/bash
# Boot s194 and capture FULL fastboot stdout to see loader's return reason.
export MSYS_NO_PATHCONV=1
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
A=/mnt/d/桌面/adb-fastboot/adb.exe
echo "=== to ABL ==="
"$A" reboot bootloader >/dev/null 2>&1
for i in $(seq 1 30); do sleep 2; p=$(timeout 6 "$F" getvar product 2>&1 | tr -d '\r' | grep -i product: | head -1); case "$p" in *star*) echo "ABL ok"; break;; esac; done
echo "=== boot s194 FULL output ==="
timeout 120 "$F" boot C:/ios26/s194-boot.img 2>&1 | tr -d '\r'
echo "=== after boot: device state every 2s for 30s ==="
for i in $(seq 1 15); do
  sleep 2
  p=$(timeout 4 "$F" -s xnuloader getvar product 2>&1 | tr -d '\r' | grep -i product: | head -1)
  echo "  t+$((i*2))s loader=${p:-GONE}"
done
