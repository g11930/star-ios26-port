#!/bin/bash
# P31 黑屏诊断:等内核归还后抓日志 + 录制数据(只读,不改设备状态)
F=/d/桌面/adb-fastboot/fastboot.exe
A=/d/桌面/adb-fastboot/adb.exe
LOG=/c/ios26/p31b-run.log
export MSYS_NO_PATHCONV=1

echo "[$(date +%H:%M:%S)] waiting for kernel return (loader_return_after=420)" >> "$LOG"
# 探测 loader fastboot 上线(内核归还后才会应答),最多再等 8 分钟
SEEN=0
for i in $(seq 1 96); do
  R=$(timeout 8 "$F" getvar product 2>&1 | head -1)
  if echo "$R" | grep -q "xnuloader"; then
    SEEN=1
    echo "[$i $(date +%H:%M:%S)] loader online: $R" >> "$LOG"
    break
  fi
  sleep 5
done
if [ "$SEEN" != "1" ]; then
  echo "[$(date +%H:%M:%S)] loader never came online" >> "$LOG"
  exit 1
fi

# 内核返回码
timeout 15 "$F" getvar result >> "$LOG" 2>&1
echo "" >> "$LOG"

# 日志:必须先 oem log 再 get_staged(oem log 会冲掉内核日志所以只发一次)
echo "[$(date +%H:%M:%S)] oem log" >> "$LOG"
timeout 60 "$F" oem log >> "$LOG" 2>&1
rm -f /c/ios26/p31b-staged.bin
timeout 300 "$F" get_staged /c/ios26/p31b-staged.bin >> "$LOG" 2>&1
ls -l /c/ios26/p31b-staged.bin >> "$LOG" 2>&1

# 录制:内核若留下了 screen recording,这里暂存并取回
echo "[$(date +%H:%M:%S)] oem recording" >> "$LOG"
timeout 60 "$F" oem recording >> "$LOG" 2>&1
rm -f /c/ios26/p31b-recording.bin
timeout 300 "$F" get_staged /c/ios26/p31b-recording.bin >> "$LOG" 2>&1
ls -l /c/ios26/p31b-recording.bin >> "$LOG" 2>&1

echo "[$(date +%H:%M:%S)] done" >> "$LOG"
