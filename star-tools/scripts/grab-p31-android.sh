#!/bin/bash
# P31 挂死后:等 Android 上线,取 sda24 logdump(预计是 P30 旧日志,用于确认)
A=/d/桌面/adb-fastboot/adb.exe
LOG=/c/ios26/p31-android.log
export MSYS_NO_PATHCONV=1

echo "[$(date +%H:%M:%S)] polling for Android" >> "$LOG"
UP=0
for i in $(seq 1 90); do
  DEV=$(timeout 10 "$A" devices 2>/dev/null | grep -E "device$" | head -1)
  if [ -n "$DEV" ]; then
    echo "[$i $(date +%H:%M:%S)] android: $DEV" >> "$LOG"
    UP=1
    break
  fi
  sleep 8
done
if [ "$UP" != "1" ]; then
  echo "[$(date +%H:%M:%S)] no android in 12min" >> "$LOG"
  exit 1
fi

# 等 su 就绪
for i in $(seq 1 20); do
  if timeout 10 "$A" shell "su -c 'echo ok'" 2>/dev/null | grep -q ok; then
    echo "[$(date +%H:%M:%S)] su ready" >> "$LOG"
    break
  fi
  sleep 5
done

echo "[$(date +%H:%M:%S)] reading sda24 logdump" >> "$LOG"
timeout 120 "$A" shell "su -c 'dd if=/dev/block/sda24 bs=4096 count=4096 2>/dev/null | base64'" 2>/dev/null | tr -d '\r\n ' | base64 -d > /c/ios26/p31-logdump.bin
ls -l /c/ios26/p31-logdump.bin >> "$LOG" 2>&1
grep -a -c "END OF LOG" /c/ios26/p31-logdump.bin >> "$LOG" 2>&1
grep -a -o "mach_kernel: [0-9.]*s" /c/ios26/p31-logdump.bin 2>/dev/null | tail -3 >> "$LOG"
echo "[$(date +%H:%M:%S)] done" >> "$LOG"
