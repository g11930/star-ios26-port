#!/bin/bash
# Pull the head of the logdump partition (sda24) and keep the newest run's text.
set -u
export MSYS_NO_PATHCONV=1
A=/d/桌面/adb-fastboot/adb.exe
OUT=/c/ios26/logdump.bin

timeout 240 "$A" shell "su -c 'dd if=/dev/block/sda24 bs=4096 count=1024 2>/dev/null | base64'" \
	| tr -d '\r\n ' | base64 -d > "$OUT" 2>/dev/null
echo "logdump head: $(stat -c %s "$OUT" 2>/dev/null) bytes"
echo "=== 首行 ==="
head -3 "$OUT" | strings | head -3
echo "=== 是否含 P33 特征（fbpaint） ==="
grep -a -c "painted the panel memory" "$OUT" 2>/dev/null
echo "=== END OF LOG 位置 ==="
grep -a -b "== END OF LOG ==" "$OUT" 2>/dev/null | head -3
echo "=== 末尾 ==="
tail -6 "$OUT" | strings | tail -6
