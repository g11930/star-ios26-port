#!/bin/bash
# Pull the GPU firmware (a660_*) from the phone's Android /vendor/firmware, plus what else the driver needs.
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
A=/mnt/d/桌面/adb-fastboot/adb.exe
OUT=/root/star26/s111/fw-gpu
mkdir -p $OUT

echo "=== back to Android ==="
timeout 15 "$F" -s xnuloader reboot >/dev/null 2>&1
for i in $(seq 1 30); do
  sleep 4
  ad=$("$A" devices 2>/dev/null | tr -d '\r' | grep -c 'device$')
  [ "$ad" -ge 1 ] && { echo "android up after $((i*4))s"; break; }
done

"$A" root >/dev/null 2>&1; sleep 4
"$A" wait-for-device
echo "=== whoami ==="
"$A" shell id 2>&1 | head -2

echo "=== list gpu firmware on the phone ==="
"$A" shell ls /vendor/firmware/ 2>&1 | grep -iE 'a6[0-9]0|a6xx|zap|gmu|sqe' | head -20

echo "=== pull ==="
for f in a660_gmu.bin a660_sqe.fw a660_zap.mdt a660_zap.b02 a660_zap.mbn a660_zap.b00 a660_zap.b01 \
         a630_gmu.bin a630_sqe.fw a630_zap.mdt a630_zap.b02; do
  "$A" pull /vendor/firmware/$f $OUT/$f >/dev/null 2>&1 && echo "got $f $(stat -c%s $OUT/$f)"
done

echo "=== what we ended with ==="
ls -la $OUT
</bash>
