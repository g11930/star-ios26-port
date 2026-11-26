#!/bin/bash
# Wait for the loader to take USB back (loader_return_after=600 or an early panic),
# then pull the live kernel log. Polls until getvar answers.
export MSYS_NO_PATHCONV=1
F=/d/桌面/adb-fastboot/fastboot.exe
LOG=/c/ios26/p16-run.log
: > "$LOG"
for i in $(seq 1 45); do
  sleep 15
  R=$(timeout 12 "$F" getvar result 2>&1 | tr -d '\r')
  if echo "$R" | grep -q "result:"; then
    echo "[${i}] LINK UP: $R" >> "$LOG"
    timeout 30 "$F" oem log >> "$LOG" 2>&1
    sleep 2
    timeout 120 "$F" get_staged "C:\\ios26\\p16-klog.txt" >> "$LOG" 2>&1
    ls -la /c/ios26/p16-klog.txt >> "$LOG" 2>&1
    echo "DONE" >> "$LOG"
    exit 0
  fi
  echo "[${i}] no link ($(date +%H:%M:%S))" >> "$LOG"
done
echo "TIMEOUT: never got a link" >> "$LOG"
