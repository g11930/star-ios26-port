#!/bin/bash
bash /mnt/d/桌面/star26-deps/scripts/build-star-native.sh >/dev/null 2>&1
echo "errors: $(grep -c 'error:' /mnt/c/ios26/star-native-build.log)"
tail -2 /mnt/c/ios26/star-native-build.log
cd /mnt/d/桌面/star26-deps/scripts
N=170 bash ./make-s135.sh 2>&1 | grep 'boot.img' | tail -1
</>
