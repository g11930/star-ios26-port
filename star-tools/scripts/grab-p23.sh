#!/bin/bash
# Wait out loader_return_after=600, then read the log the loader staged on the logdump partition.
export MSYS_NO_PATHCONV=1
A=/d/桌面/adb-fastboot/adb.exe
LOG=/c/ios26/p23-run.log
: > "$LOG"

sleep 620
for i in $(seq 1 30); do
  if "$A" devices 2>/dev/null | grep -q "device$"; then
    echo "[$i $(date +%H:%M:%S)] android is back" >> "$LOG"
    break
  fi
  echo "[$i $(date +%H:%M:%S)] waiting for android" >> "$LOG"
  sleep 10
done

"$A" shell "su -c 'dd if=/dev/block/sda24 bs=4096 count=4096 2>/dev/null | base64'" > /c/ios26/p23-logdump.b64 2>/dev/null
echo "b64 bytes: $(wc -c < /c/ios26/p23-logdump.b64)" >> "$LOG"
tr -d '\r\n ' < /c/ios26/p23-logdump.b64 | base64 -d > /c/ios26/p23-logdump.bin 2>/dev/null
ls -la /c/ios26/p23-logdump.bin >> "$LOG"
echo "DONE" >> "$LOG"
