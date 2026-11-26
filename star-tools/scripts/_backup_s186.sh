#!/bin/bash
set -e
BK=/mnt/d/桌面/star26-deps/backup/20261119-s186-sb-thumb
mkdir -p "$BK"
cp /root/star26/star-native/bsd/dev/star/star_platform_stubs.c "$BK"/
cp /root/star26/star-native/bsd/kern/kern_exec.c "$BK"/
cp /root/star26/s111/work/rootbuild/root/etc/rc.jobs "$BK"/
echo "backup: $(ls -1 $BK | tr '\n' ' ')"