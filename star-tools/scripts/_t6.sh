#!/bin/bash
cd /mnt/d/桌面/star26-deps/scripts
bash ./build-star-native.sh > /tmp/kb17.log 2>&1
rc=$?
echo "BUILD_EXIT=$rc"; grep -c 'error:' /tmp/kb17.log
grep -E 'error:' /tmp/kb17.log | head -3
if [ "$rc" -eq 0 ]; then N=188 bash ./make-s139.sh 2>&1 | grep -E 'boot.img' | tail -1; fi