#!/bin/bash
# 完整备份 s90 基线（当前唯一能跑到 digitizer 的干净版本）
set -e
SRC=/root/star26/s90
BAK=/root/star26/s90.backup-20261117
C=/mnt/c/ios26

echo "=== [$(date +%T)] s90 source inventory ==="
du -sh "$SRC"
ls -la "$SRC" "$SRC/parts"

echo "=== [$(date +%T)] remove stale backup if any ==="
if [ -e "$BAK" ]; then
    echo "WARN: backup target already exists, rotating"
    mv -f "$BAK" "${BAK}.old-$(date +%s)"
fi

echo "=== [$(date +%T)] copy s90 tree ==="
cp -a "$SRC" "$BAK"
echo "copied -> $BAK"

echo "=== [$(date +%T)] verify byte-identical ==="
diff -rq "$SRC" "$BAK" && echo "TREE IDENTICAL"
echo "--- md5 key artifacts ---"
md5sum "$SRC/s90-boot.img" "$BAK/s90-boot.img"
md5sum "$SRC/parts/kernel" "$BAK/parts/kernel"
md5sum "$SRC/parts/ramdisk" "$BAK/parts/ramdisk"

echo "=== [$(date +%T)] backup C: side artifact ==="
cp -f "$C/s90-boot.img" "$C/s90-boot.backup-20261117.img"
md5sum "$C/s90-boot.img" "$C/s90-boot.backup-20261117.img"

echo "=== [$(date +%T)] write backup manifest ==="
{
  echo "s90 backup 2026-11-17"
  echo "source: $SRC"
  echo "backup: $BAK"
  echo "time:   $(date)"
  echo "--- md5 ---"
  md5sum "$BAK/s90-boot.img" "$BAK/parts/"*
} > "$BAK/MANIFEST.txt"
cat "$BAK/MANIFEST.txt"
echo "=== [$(date +%T)] DONE: s90 backed up ==="
