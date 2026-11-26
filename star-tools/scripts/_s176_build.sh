#!/bin/bash
bash /mnt/d/桌面/star26-deps/scripts/build-star-native.sh > /tmp/kb3.log 2>&1
echo "BUILD_EXIT=$?"; grep -E 'OK __kalloc|PASS' /tmp/kb3.log | tail -2
cd /mnt/d/桌面/star26-deps/scripts
N=176 bash ./make-s139.sh 2>&1 | grep -E 'boot.img' | tail -1
</>
