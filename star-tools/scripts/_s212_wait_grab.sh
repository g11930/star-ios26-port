#!/bin/bash
F="/d/桌面/adb-fastboot/fastboot.exe"
export MSYS_NO_PATHCONV=1
TAG=${1:-$(date +%H%M%S)}
WAIT=${2:-240}
echo "=== wait ${WAIT}s ==="
sleep "$WAIT"
echo "=== device ==="
timeout 12 "$F" devices 2>&1 | tr -d '\r'
echo "=== get_staged ==="
rm -f /c/ios26/s212-staged.bin
timeout 120 "$F" -s xnuloader get_staged C:/ios26/s212-staged.bin 2>&1 | tr -d '\r' | tail -4
sz=$(stat -c%s /c/ios26/s212-staged.bin 2>/dev/null || echo 0)
echo "size=$sz"
[ "$sz" -gt 100 ] && cp -f /c/ios26/s212-staged.bin "/c/ios26/s212-$TAG.bin" && echo "saved /c/ios26/s212-$TAG.bin"
