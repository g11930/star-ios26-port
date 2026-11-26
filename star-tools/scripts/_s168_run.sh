#!/bin/bash
python3 /mnt/d/桌面/star26-deps/scripts/_retarget_se.py
bash /mnt/d/桌面/star26-deps/scripts/build-star-native.sh >/dev/null 2>&1
echo "errors: $(grep -c 'error:' /mnt/c/ios26/star-native-build.log)"
grep 'error:' /mnt/c/ios26/star-native-build.log | head -4
cd /mnt/d/桌面/star26-deps/scripts
N=168 bash ./make-s135.sh 2>&1 | grep 'boot.img' | tail -1
sed 's/TAG=s131/TAG=s168/' _s131_flash.sh > _s168_flash.sh
python3 _patch_wait.py _s168_flash.sh
bash _s168_flash.sh
</>
