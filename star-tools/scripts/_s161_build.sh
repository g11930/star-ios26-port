#!/bin/bash
set -e
cd /root/star26/star-native
python3 /mnt/d/桌面/star26-deps/scripts/stage8-kalloc-backfill.py 2>&1 | tail -3
bash /mnt/d/桌面/star26-deps/scripts/build-star-native.sh > /dev/null 2>&1
tail -3 /mnt/c/ios26/star-native-build.log

C=/root/star26/s111/parts/cmdline
grep -q 'touchscreen=1' $C || sed -i 's/$/ touchscreen=1/' $C
grep -o 'touchscreen=1' $C

cd /mnt/d/桌面/star26-deps/scripts
N=161 bash ./make-s135.sh 2>&1 | grep -E 'boot.img' | tail -2
</>
