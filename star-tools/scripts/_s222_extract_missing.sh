#!/bin/bash
# 从 systemos.dmg 用 7z 提取 3 个稀疏 dyldlinkedit 分片，补齐 /root/dsc26
set -u
DMG=/root/star26/ipsw/systemos.dmg
OUT=/root/dsc26/System/Library/Caches/com.apple.dyld
TMP=/root/dsc26_fix
mkdir -p "$TMP"

for name in \
  dyld_shared_cache_arm64e.35.dyldlinkedit \
  dyld_shared_cache_arm64e.72.dyldlinkedit \
  dyld_shared_cache_arm64e.83.dyldlinkedit; do
  src="System/Library/Caches/com.apple.dyld/$name"
  echo "=== extracting $name ==="
  rm -f "$TMP/$name"
  timeout 300 7z e -so "$DMG" "$src" > "$TMP/$name" 2>"$TMP/$name.err"
  rc=$?
  sz=$(stat -c %s "$TMP/$name" 2>/dev/null || echo 0)
  echo "  rc=$rc size=$sz"
  if [ "$rc" -ne 0 ] || [ "$sz" -lt 1000000 ]; then
    echo "  FAILED, err:"; cat "$TMP/$name.err" | head -5
  fi
done
echo
echo "=== 结果 ==="
ls -lah "$TMP"/*.dyldlinkedit 2>/dev/null
