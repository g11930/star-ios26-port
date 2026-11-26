#!/bin/bash
python3 /mnt/d/桌面/star26-deps/scripts/_move_helper.py
bash /mnt/d/桌面/star26-deps/scripts/build-star-native.sh >/dev/null 2>&1
echo "errors: $(grep -c 'error:' /mnt/c/ios26/star-native-build.log)"
grep 'error:' /mnt/c/ios26/star-native-build.log | head -5
tail -2 /mnt/c/ios26/star-native-build.log
</>
