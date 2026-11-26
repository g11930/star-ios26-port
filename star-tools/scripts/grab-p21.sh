#!/bin/bash
# Wait out loader_return_after=600 (counted from the fastboot boot), then take the log once.
# No polling before that: the loader only answers once the kernel has given the CPU back, and
# a getvar storm in the window between is what made an earlier run reboot at the 120 s fallback.
export MSYS_NO_PATHCONV=1
F=/d/桌面/adb-fastboot/fastboot.exe
LOG=/c/ios26/p21-run.log
: > "$LOG"

# boot was issued at 02:57:00; 600 s lands at 03:07:00. Sleep past it, then try for 6 minutes.
sleep 300
for i in $(seq 1 18); do
  R=$(timeout 15 "$F" getvar result 2>&1 | tr -d '\r')
  echo "[$i $(date +%H:%M:%S)] $R" >> "$LOG"
  if echo "$R" | grep -q "result:"; then
    timeout 40 "$F" oem log >> "$LOG" 2>&1
    sleep 2
    timeout 180 "$F" get_staged "C:\\ios26\\p21-klog.txt" >> "$LOG" 2>&1
    ls -la /c/ios26/p21-klog.txt >> "$LOG" 2>&1
    echo "DONE" >> "$LOG"
    exit 0
  fi
  sleep 20
done
echo "TIMEOUT: loader never answered" >> "$LOG"
