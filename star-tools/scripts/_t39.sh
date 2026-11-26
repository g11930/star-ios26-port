#!/bin/bash
set -e
B=/root/star26/s111
BK=/mnt/d/桌面/star26-deps/backup/20261119-s201-touchlat
mkdir -p "$BK"
cp $B/parts/cmdline "$BK"/cmdline.s200
OLD=$(cat $B/parts/cmdline)
case "$OLD" in
  *touch_lat=*) echo "already there";;
  *) printf '%s touch_lat=1' "$OLD" > $B/parts/cmdline;;
esac
cat $B/parts/cmdline; echo
cd /mnt/d/桌面/star26-deps/scripts
N=201 bash ./make-s139.sh 2>&1 | grep -E 'boot.img' | tail -1