#!/bin/bash
# s72 runner: incremental build of star-native (kalloc gate runs inside).
cd /root/star26/star-native || exit 1
bash /mnt/d/桌面/star26-deps/scripts/build-star-native.sh > /tmp/build_s72.log 2>&1
echo "BUILD_EXIT=$?"
tail -24 /tmp/build_s72.log
