#!/bin/bash
bash /mnt/d/桌面/star26-deps/scripts/build-star-native.sh > /tmp/kb15.log 2>&1
echo "BUILD_EXIT=$?"; grep -c 'error:' /tmp/kb15.log
cd /mnt/d/桌面/star26-deps/scripts
N=187 bash ./make-s139.sh 2>&1 | grep -E 'boot.img' | tail -1