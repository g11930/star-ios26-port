#!/bin/bash
A=/mnt/d/桌面/adb-fastboot/adb.exe
OUT=/root/star26/s111/fw-gpu
mkdir -p $OUT
echo "=== permissions ==="
"$A" shell ls -l /vendor/firmware/a660_gmu.bin /vendor/firmware/a660_sqe.fw /vendor/firmware/a660_zap.mdt /vendor/firmware/a660_zap.b02 2>&1

echo "=== try reading through cat ==="
for f in a660_gmu.bin a660_sqe.fw a660_zap.mdt a660_zap.b02; do
  "$A" shell "cat /vendor/firmware/$f" > $OUT/$f 2>/dev/null
  sz=$(stat -c%s $OUT/$f 2>/dev/null || echo 0)
  echo "$f -> $sz bytes  head=$(head -c 16 $OUT/$f | od -An -tx1 | tr -d ' \n')"
done
ls -la $OUT
</bash>
