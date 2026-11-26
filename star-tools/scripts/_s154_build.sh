#!/bin/bash
set -e
R=/root/star26/s111/work/rootbuild/root
touch $R/etc/sbmetal-late
ls -l $R/etc/sbmetal-late
C=/root/star26/s111/parts/cmdline
cp -f $C $C.pre-s154
sed -i 's/ star_sbmetal=1//' $C
grep -o 'star_sbmetal' $C || echo "star_sbmetal removed"
grep -c 'star_sbmetal_late\|sbmetal-late' $C || true
cd /mnt/d/桌面/star26-deps/scripts
N=154 bash ./make-s139.sh 2>&1 | tail -5
