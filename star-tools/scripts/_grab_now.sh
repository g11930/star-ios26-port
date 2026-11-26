#!/bin/bash
# 只读抓当前 loader staged 日志，不改任何东西（Git Bash 版）
F="/d/桌面/adb-fastboot/fastboot.exe"
STAGED="C:/ios26/now-staged.bin"
LOCAL="/c/ios26/now-staged.bin"
export MSYS_NO_PATHCONV=1
rm -f "$LOCAL"
echo "=== device ==="
timeout 10 "$F" devices 2>&1 | tr -d '\r'
echo "=== oem log kick ==="
timeout 20 "$F" -s xnuloader oem log 2>&1 | tr -d '\r' | tail -3
echo "=== get_staged ==="
timeout 120 "$F" -s xnuloader get_staged "$STAGED" 2>&1 | tr -d '\r' | tail -3
sz=$(stat -c%s "$LOCAL" 2>/dev/null || echo 0)
echo "size=$sz"
if [ "$sz" -gt 100 ]; then
  cp -f "$LOCAL" "/c/ios26/now-$(date +%H%M%S).bin"
  echo "saved: /c/ios26/now-$(date +%H%M%S).bin"
fi
