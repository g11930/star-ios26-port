#!/bin/bash
cd /root/star26/star-native
python3 /mnt/d/桌面/star26-deps/scripts/stage8-kalloc-backfill.py 2>&1 | tail -2
bash /mnt/d/桌面/star26-deps/scripts/build-star-native.sh > /tmp/kb7.log 2>&1
echo "BUILD_EXIT=$?"; grep -E 'PASS' /tmp/kb7.log | tail -1
cd /mnt/d/桌面/star26-deps/scripts
N=179 bash ./make-s139.sh 2>&1 | grep -E 'boot.img' | tail -1
</>
