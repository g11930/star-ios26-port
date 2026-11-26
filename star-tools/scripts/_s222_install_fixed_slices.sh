#!/bin/bash
set -e
DST=/root/dsc26/System/Library/Caches/com.apple.dyld
mkdir -p /root/dsc26_bad_backup
for n in 35 72 83; do
  f="dyld_shared_cache_arm64e.$n.dyldlinkedit"
  cp "$DST/$f" "/root/dsc26_bad_backup/$f"
  cp "/root/dsc26_fix/$f" "$DST/$f"
  echo "installed $f size=$(stat -c%s "$DST/$f") md5=$(md5sum "$DST/$f" | cut -d' ' -f1)"
done
