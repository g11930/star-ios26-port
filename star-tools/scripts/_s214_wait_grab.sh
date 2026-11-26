#!/bin/bash
# s214: 等待指定秒数后 kick+抓日志，保存到带时间戳文件（Git Bash 版）
F="/d/桌面/adb-fastboot/fastboot.exe"
export MSYS_NO_PATHCONV=1
WAIT=${1:-240}
TAG=${2:-s214}
echo "=== wait ${WAIT}s ==="
sleep "$WAIT"
echo "=== device ==="
timeout 10 "$F" -s xnuloader devices 2>&1 | tr -d '\r'
echo "=== oem log kick ==="
timeout 20 "$F" -s xnuloader oem log 2>&1 | tr -d '\r' | tail -2
echo "=== get_staged ==="
STAGED="C:/ios26/now-staged.bin"
timeout 120 "$F" -s xnuloader get_staged "$STAGED" 2>&1 | tr -d '\r' | tail -2
OUT="/c/ios26/${TAG}-$(date +%H%M%S).bin"
cp -f "/c/ios26/now-staged.bin" "$OUT"
SZ=$(stat -c%s "$OUT" 2>/dev/null || echo 0)
echo "=== saved $OUT size=$SZ ==="
