#!/bin/bash
# P26's log. Same shape as P24's, with one fix: fastboot.exe is a Windows program, so the
# output path has to be relative after cd -- /c/ios26/ is a MSYS path it cannot open.
export MSYS_NO_PATHCONV=1
A=/d/桌面/adb-fastboot/adb.exe
F=/d/桌面/adb-fastboot/fastboot.exe
DIR=/c/ios26
LOG=$DIR/p27-run.log
: > "$LOG"

echo "[$(date +%H:%M:%S)] booted; waiting 560 s for loader_return_after=600" >> "$LOG"
sleep 560
cd "$DIR" || exit 1

got=0
for i in $(seq 1 80); do
  if timeout 8 "$F" devices 2>/dev/null | grep -qi "xnuloader"; then
    echo "[$i $(date +%H:%M:%S)] loader is back; taking staged log" >> "$LOG"
    rm -f p27-staged.bin
    timeout 90 "$F" -s xnuloader get_staged p27-staged.bin >> "$LOG" 2>&1
    if [ -s p27-staged.bin ] && [ "$(stat -c %s p27-staged.bin)" -gt 65536 ]; then
      echo "[$i $(date +%H:%M:%S)] staged log: $(stat -c %s p27-staged.bin) bytes" >> "$LOG"
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
      "$A" shell "su -c 'dd if=/dev/block/sda24 bs=4096 count=4096 2>/dev/null | base64'" > p27-logdump.b64 2>/dev/null
      echo "b64 bytes: $(wc -c < p27-logdump.b64)" >> "$LOG"
      tr -d '\r\n ' < p27-logdump.b64 | base64 -d > p27-logdump.bin 2>/dev/null
      ls -la p27-logdump.bin >> "$LOG"
      cp -f p27-logdump.bin p27-staged.bin
      got=2
      break
    fi
    sleep 10
  done
fi

echo "DONE got=$got" >> "$LOG"
