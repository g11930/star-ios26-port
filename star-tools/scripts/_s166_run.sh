#!/bin/bash
python3 /mnt/d/桌面/star26-deps/scripts/_kick_probe.py
bash /mnt/d/桌面/star26-deps/scripts/build-star-native.sh >/dev/null 2>&1
grep -c 'error:' /mnt/c/ios26/star-native-build.log
tail -2 /mnt/c/ios26/star-native-build.log
cd /mnt/d/桌面/star26-deps/scripts
N=166 bash ./make-s135.sh 2>&1 | grep 'boot.img' | tail -1
sed 's/TAG=s131/TAG=s166/' _s131_flash.sh > _s166_flash.sh
python3 _patch_wait.py _s166_flash.sh
bash _s166_flash.sh
</>
