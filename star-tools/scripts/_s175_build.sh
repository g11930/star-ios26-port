#!/bin/bash
cd /root/star26/star-native
python3 /mnt/d/桌面/star26-deps/scripts/stage8-kalloc-backfill.py 2>&1 | tail -4
bash /mnt/d/桌面/star26-deps/scripts/build-star-native.sh > /tmp/kb2.log 2>&1
echo "BUILD_EXIT=$?"
grep -E 'OK __kalloc|PASS' /tmp/kb2.log | tail -3
cd /mnt/d/桌面/star26-deps/scripts
N=175 bash ./make-s139.sh 2>&1 | grep -E 'boot.img' | tail -1
</>
