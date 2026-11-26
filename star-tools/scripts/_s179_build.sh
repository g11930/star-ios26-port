#!/bin/bash
bash /mnt/d/桌面/star26-deps/scripts/build-star-native.sh > /tmp/kb6.log 2>&1
echo "BUILD_EXIT=$?"
grep -c 'error:' /tmp/kb6.log
grep -E 'error:' /tmp/kb6.log | head -5
grep -E 'PASS' /tmp/kb6.log | tail -1
</>
