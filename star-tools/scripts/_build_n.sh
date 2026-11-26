#!/bin/bash
N=${N:-189}
cd /mnt/d/桌面/star26-deps/scripts
bash ./build-star-native.sh > /tmp/kb18.log 2>&1
rc=$?
echo "BUILD_EXIT=$rc"; grep -c 'error:' /tmp/kb18.log
grep -E 'error:' /tmp/kb18.log | head -3
if [ "$rc" -eq 0 ]; then N=$N bash ./make-s139.sh 2>&1 | grep -E 'boot.img' | tail -1; fi