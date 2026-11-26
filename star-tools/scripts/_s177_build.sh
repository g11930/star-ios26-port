#!/bin/bash
bash /mnt/d/桌面/star26-deps/scripts/build-star-native.sh > /tmp/kb4.log 2>&1
echo "BUILD_EXIT=$?"; grep -E 'PASS' /tmp/kb4.log | tail -1
cd /mnt/d/桌面/star26-deps/scripts
N=177 bash ./make-s139.sh 2>&1 | grep -E 'boot.img' | tail -1
</>
