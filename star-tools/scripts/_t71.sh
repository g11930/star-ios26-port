#!/bin/bash
echo "=== build script ==="
cat /mnt/d/桌面/star26-deps/scripts/build-star-native.sh
echo "=== stage8 present? ==="
ls -l --time-style=+%F_%T /root/star26/star-native/stage8-kalloc-backfill.py 2>/dev/null
echo "=== recent build log head ==="
head -20 /tmp/kb21.log