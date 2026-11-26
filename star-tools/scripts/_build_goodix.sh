#!/bin/bash
python3 /mnt/d/桌面/star26-deps/scripts/_wire_tl.py
echo "=== tail of annibale_input.c ==="
tail -14 /root/star26/star-native/bsd/dev/star/annibale_input.c
echo "=== build ==="
bash /mnt/d/桌面/star26-deps/scripts/build-star-native.sh > /dev/null 2>&1
grep -n 'error:' /mnt/c/ios26/star-native-build.log | head -12
tail -3 /mnt/c/ios26/star-native-build.log
</