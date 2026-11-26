#!/bin/bash
set -e
cp -f /root/star26/s34/work/root/lib/libannibale-sbmetal-experiment.dylib \
      /root/star26/s111/work/rootbuild/root/lib/libannibale-sbmetal-experiment.dylib
ls -l /root/star26/s111/work/rootbuild/root/lib/libannibale-sbmetal-experiment.dylib
cd /mnt/d/桌面/star26-deps/scripts
N=$1 bash ./make-s139.sh
sed "s/TAG=s131/TAG=s$1/" _s131_flash.sh > _s$1_flash.sh
python3 _patch_wait.py _s$1_flash.sh
bash _s$1_flash.sh
