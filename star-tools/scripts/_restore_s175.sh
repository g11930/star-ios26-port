#!/bin/bash
set -e
BK=/mnt/d/桌面/star26-deps/backup/20261118-s175-mesa-cache
cp "$BK/star_platform_stubs.c" /root/star26/star-native/bsd/dev/star/star_platform_stubs.c
cp "$BK/rc.jobs" /root/star26/s111/work/rootbuild/root/etc/rc.jobs
echo "stubs restored from s175 backup"
grep -c 'ANNIBALE_' /root/star26/star-native/bsd/dev/star/star_platform_stubs.c
echo "--- kern_exec namematches present?"
grep -c 'namematches' /root/star26/star-native/bsd/kern/kern_exec.c