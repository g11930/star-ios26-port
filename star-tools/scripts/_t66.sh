#!/bin/bash
set -e
B=/root/star26/s111
cp $B/parts/cmdline /tmp/cmdline.s208
printf '%s touch_diag=0 touch_lat=1 fb_diff=1' "$(cat /tmp/cmdline.s208 | sed 's/ touch_lat=1$/ touch_lat=1/')" > $B/parts/cmdline
tail -c 90 $B/parts/cmdline; echo
cd /mnt/d/桌面/star26-deps/scripts
bash ./build-star-native.sh > /tmp/kb21.log 2>&1
rc=$?; echo "BUILD_EXIT=$rc errors=$(grep -c 'error:' /tmp/kb21.log)"
[ "$rc" -eq 0 ] && N=209 bash ./make-s139.sh 2>&1 | grep -E 'boot.img' | tail -1