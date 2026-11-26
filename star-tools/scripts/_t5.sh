#!/bin/bash
set -e
BK=/mnt/d/桌面/star26-deps/backup/20261119-s188-touchlines
mkdir -p "$BK"
cp /root/star26/star-native/bsd/dev/star/annibale_goodix.c "$BK"/annibale_goodix.c
echo "backup ok"
cd /mnt/d/桌面/star26-deps/scripts
python3 ./stage8-kalloc-backfill.py > /tmp/gate_s188.log 2>&1 || echo "GATE_FAIL"
tail -2 /tmp/gate_s188.log
bash ./build-star-native.sh > /tmp/kb16.log 2>&1 || true
echo "BUILD_EXIT=$?"; grep -c 'error:' /tmp/kb16.log
grep -E 'error:' /tmp/kb16.log | head -3
N=188 bash ./make-s139.sh 2>&1 | grep -E 'boot.img' | tail -1