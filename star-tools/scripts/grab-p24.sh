#!/bin/bash
# P24's log: wait out loader_return_after=600, then take the staged copy the moment the loader is
# back at its fastboot endpoint (its serial is xnuloader). If that window is missed, read the logdump
# partition once Android returns -- the loader writes the same text there before it cold-restarts.
export MSYS_NO_PATHCONV=1
A=/d/桌面/adb-fastboot/adb.exe
F=/d/桌面/adb-fastboot/fastboot.exe
LOG=/c/ios26/p24-run.log
: > "$LOG"

echo "[$(date +%H:%M:%S)] booted; waiting 560 s for loader_return_after=600" >> "$LOG"
sleep 560

got=0
for i in $(seq 1 80); do
  if timeout 8 "$F" devices 2>/dev/null | grep -qi "xnuloader"; then
    echo "[$i $(date +%H:%M:%S)] loader is back; taking staged log" >> "$LOG"
    timeout 90 "$F" -s xnuloader get_staged /c/ios26/p24-staged.bin >> "$LOG" 2>&1
    if [ -s /c/ios26/p24-staged.bin ] && [ "$(stat -c %s /c/ios26/p24-staged.bin)" -gt 65536 ]; then
      echo "[$i $(date +%H:%M:%S)] staged log: $(stat -c %s /c/ios26/p24-staged.bin) bytes" >> "$LOG"
      got=1
      break
    fi
  fi
  if timeout 8 "$A" devices 2>/dev/null | grep -q "device$"; then
    echo "[$i $(date +%H:%M:%S)] android is back; reading logdump instead" >> "$LOG"
    break
  fi
  sleep 5
done

if [ "$got" = 0 ]; then
  for i in $(seq 1 40); do
    if timeout 8 "$A" devices 2>/dev/null | grep -q "device$"; then
      echo "[$i $(date +%H:%M:%S)] android is up; dd logdump" >> "$LOG"
      "$A" shell "su -c 'dd if=/dev/block/sda24 bs=4096 count=4096 2>/dev/null | base64'" > /c/ios26/p24-logdump.b64 2>/dev/null
      echo "b64 bytes: $(wc -c < /c/ios26/p24-logdump.b64)" >> "$LOG"
      tr -d '\r\n ' < /c/ios26/p24-logdump.b64 | base64 -d > /c/ios26/p24-logdump.bin 2>/dev/null
      ls -la /c/ios26/p24-logdump.bin >> "$LOG"
      got=2
      break
    fi
    sleep 10
  done
fi

echo "DONE got=$got" >> "$LOG"
