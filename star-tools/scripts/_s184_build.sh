#!/bin/bash
bash /mnt/d/桌面/star26-deps/scripts/build-star-native.sh > /tmp/kb12.log 2>&1
echo "BUILD_EXIT=$?"; grep -c 'error:' /tmp/kb12.log; grep -E 'error:' /tmp/kb12.log | head -3
cd /mnt/d/桌面/star26-deps/scripts
N=184 bash ./make-s139.sh 2>&1 | grep -E 'boot.img' | tail -1