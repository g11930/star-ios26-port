#!/bin/bash
# s212 抓日志：只 get_staged，绝不调用 oem log（避免冲掉 panic 文本）
F="/d/桌面/adb-fastboot/fastboot.exe"
STAGED="C:/ios26/s212-staged.bin"
LOCAL="/c/ios26/s212-staged.bin"
TAG=${1:-$(date +%H%M%S)}
export MSYS_NO_PATHCONV=1
echo "=== wait for kernel progress (75s) ==="
sleep 75
echo "=== device state ==="
timeout 12 "$F" devices 2>&1 | tr -d '\r'
echo "=== get_staged ==="
rm -f "$LOCAL"
timeout 120 "$F" -s xnuloader get_staged "$STAGED" 2>&1 | tr -d '\r' | tail -5
sz=$(stat -c%s "$LOCAL" 2>/dev/null || echo 0)
echo "size=$sz"
if [ "$sz" -gt 100 ]; then
  cp -f "$LOCAL" "/c/ios26/s212-$TAG.bin"
  echo "saved: /c/ios26/s212-$TAG.bin"
fi
