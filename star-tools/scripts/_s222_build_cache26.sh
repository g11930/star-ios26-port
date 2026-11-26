#!/bin/bash
set -e
STAGE=/root/cache26_stage
rm -rf $STAGE
mkdir -p $STAGE
# 84 rewritten cache files
for f in /root/dsc26_rewritten/*; do
  ln "$f" "$STAGE/$(basename "$f")"
done
# atlas from the original cache (plain data, not code)
if [ -f /root/dsc26/System/Library/Caches/com.apple.dyld/dyld_shared_cache_arm64e.atlas ]; then
  ln /root/dsc26/System/Library/Caches/com.apple.dyld/dyld_shared_cache_arm64e.atlas "$STAGE/"
fi
echo "staged: $(ls $STAGE | wc -l) files, $(du -sl --apparent-size $STAGE | awk '{print $1}') bytes"
cd /root/apfs16
/root/star26/zeta-venv/bin/python mkapfs.py -o /root/cache26.dmg --slack 65536 Cache26=$STAGE
ls -la /root/cache26.dmg
