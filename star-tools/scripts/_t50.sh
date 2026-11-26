#!/bin/bash
set -e
B=/root/star26/s111
cp /mnt/d/桌面/star26-deps/backup/20261119-s201-touchlat/cmdline.s200 $B/parts/cmdline
echo "cmdline: $(cat $B/parts/cmdline | tail -c 60)"
cd /mnt/d/桌面/star26-deps/scripts
bash ./build-star-native.sh > /tmp/kb19.log 2>&1
rc=$?; echo "BUILD_EXIT=$rc"; grep -c 'error:' /tmp/kb19.log || true
grep -E 'error:' /tmp/kb19.log | head -3 || true
if [ "$rc" -eq 0 ]; then N=207 bash ./make-s139.sh 2>&1 | grep -E 'boot.img' | tail -1; fi