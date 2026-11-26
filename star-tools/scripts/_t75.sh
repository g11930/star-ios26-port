#!/bin/bash
set -e
cd /root/star26/star-native
git checkout -q 92fbb2e
echo "at $(git show -s --pretty='%h %s' HEAD)"
B=/root/star26/s111
printf '%s touch_diag=0 touch_lat=1 fb_diff=1' "$(cat /tmp/cmdline.s208)" > $B/parts/cmdline
cd /mnt/d/桌面/star26-deps/scripts
bash ./build-star-native.sh > /tmp/kb23.log 2>&1
echo "BUILD_EXIT=$? errors=$(grep -c 'error:' /tmp/kb23.log)"
ls -l --time-style=+%T $B/parts/kernel | awk '{print "kernel", $5}'
N=211 bash ./make-s139.sh 2>&1 | grep -E 'boot.img' | tail -1