#!/bin/bash
echo "=== logd plist in root ==="
find /root/star26/s58/work/root -iname '*logd*.plist' 2>/dev/null | head -10
echo "=== logd plist contents ==="
for f in $(find /root/star26/s58/work/root -iname 'com.apple.logd.plist' 2>/dev/null | head -2); do
  echo "--- $f"
  cat "$f" 2>/dev/null | head -40
done
echo "=== /var/log /var/db in root tree ==="
find /root/star26/s58/work/root -type d \( -path '*/var/log' -o -path '*/var/db/log*' \) 2>/dev/null | head -10
echo "=== logdtrace shows fsync; what path? (source logs) ==="
grep -rn 'logd.*fsync\|fsync.*logd' /mnt/d/桌面/star-ios16-stable-documented-20261030/.workbuddy/memory/*.md 2>/dev/null | head -8
