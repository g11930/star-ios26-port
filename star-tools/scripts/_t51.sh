#!/bin/bash
set -e
B=/root/star26/s111
BK=/mnt/d/桌面/star26-deps/backup/20261120-s208-nodiff
mkdir -p "$BK"
cp $B/parts/cmdline "$BK"/cmdline.before
printf '%s touch_diag=0 touch_lat=1' "$(cat $B/parts/cmdline)" > $B/parts/cmdline
cp $B/parts/cmdline "$BK"/cmdline.after
echo "cmdline tail: ...$(tail -c 80 $B/parts/cmdline)"
cd /mnt/d/桌面/star26-deps/scripts
bash ./build-star-native.sh > /tmp/kb20.log 2>&1
rc=$?; echo "BUILD_EXIT=$rc"; grep -c 'error:' /tmp/kb20.log || true
grep -E 'error:' /tmp/kb20.log | head -3 || true
if [ "$rc" -eq 0 ]; then N=208 bash ./make-s139.sh 2>&1 | grep -E 'boot.img' | tail -1; fi