#!/bin/bash
A=/mnt/d/桌面/adb-fastboot/adb.exe
OUT=/root/star26/s111/fw-gpu
mkdir -p $OUT
for f in a660_gmu.bin a660_sqe.fw a660_zap.mdt a660_zap.b02; do
  "$A" exec-out cat /vendor/firmware/$f > $OUT/$f
  echo "$f -> $(stat -c%s $OUT/$f) bytes (expected from ls)"
done
md5sum $OUT/*
</bash>
