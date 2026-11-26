#!/bin/bash
python3 /mnt/d/桌面/star26-deps/scripts/_delay_probe.py
bash /mnt/d/桌面/star26-deps/scripts/build-star-native.sh >/dev/null 2>&1
tail -2 /mnt/c/ios26/star-native-build.log
cd /mnt/d/桌面/star26-deps/scripts
N=165 bash ./make-s135.sh 2>&1 | grep 'boot.img' | tail -1
sed 's/TAG=s131/TAG=s165/' _s131_flash.sh > _s165_flash.sh
python3 _patch_wait.py _s165_flash.sh
bash _s165_flash.sh
</>
