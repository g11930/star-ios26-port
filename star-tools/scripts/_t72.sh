#!/bin/bash
set -e
BK=/mnt/d/桌面/star26-deps/backup/20261120-s97diag-revert
mkdir -p "$BK"
cd /root/star26/star-native
git --no-pager diff > "$BK"/uncommitted-s97diag.patch
wc -c "$BK"/uncommitted-s97diag.patch
git checkout -- bsd/kern/kern_exec.c bsd/kern/kern_minimac.c osfmk/arm64/sleh.c
git status --short
B=/root/star26/s111
printf '%s touch_diag=0 touch_lat=1 fb_diff=1' "$(cat /tmp/cmdline.s208)" > $B/parts/cmdline
tail -c 70 $B/parts/cmdline; echo
cd /mnt/d/桌面/star26-deps/scripts
bash ./build-star-native.sh > /tmp/kb22.log 2>&1
echo "BUILD_EXIT=$? errors=$(grep -c 'error:' /tmp/kb22.log)"
ls -l --time-style=+%T $B/parts/kernel | awk '{print "kernel", $5}'
N=210 bash ./make-s139.sh 2>&1 | grep -E 'boot.img' | tail -1