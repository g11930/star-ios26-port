#!/bin/bash
# 等待设备从 s95 重启循环中稳定，报告可用状态
A=/mnt/d/桌面/adb-fastboot/adb.exe
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
echo "=== restart adb server ==="
"$A" kill-server >/dev/null 2>&1
"$A" start-server 2>&1 | tr -d '\r'
for i in $(seq 1 30); do
  sleep 2
  ad=$("$A" devices 2>/dev/null | tr -d '\r' | grep -c "device$")
  p=$(timeout 5 "$F" getvar product 2>&1 | tr -d '\r' | grep -i product: | head -1)
  pl=$(timeout 5 "$F" -s xnuloader getvar product 2>&1 | tr -d '\r' | grep -i product: | head -1)
  if [ "$ad" -gt 0 ] || echo "$p" | grep -q star || echo "$pl" | grep -q xnuloader; then
    echo "[try $i] adb=$ad product='$p' loader='$pl'"
    if [ "$ad" -gt 0 ]; then echo "STATE=ANDROID"; fi
    if echo "$p" | grep -q star; then echo "STATE=ABL_FASTBOOT"; fi
    if echo "$pl" | grep -q xnuloader; then echo "STATE=XNULOADER"; fi
    exit 0
  fi
  if [ $((i % 5)) -eq 0 ]; then echo "[try $i] adb=$ad product='${p:-none}' loader='${pl:-none}'"; fi
done
echo "STATE=UNKNOWN (no device after 60s)"
