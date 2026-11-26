#!/bin/bash
set -u
DMG=/root/star26/ipsw/systemos.dmg
OUT=/root/dsc26_fix/7zout
mkdir -p "$OUT"
for n in 35 72 83; do
  name="dyld_shared_cache_arm64e.${n}.dyldlinkedit"
  echo "=== $name ==="
  cd "$OUT"
  7z e -y "$DMG" "System/Library/Caches/com.apple.dyld/$name" > /dev/null 2>&1
  ls -lah "$OUT/$name"* 2>/dev/null | awk '{print $5, $9}'
done
