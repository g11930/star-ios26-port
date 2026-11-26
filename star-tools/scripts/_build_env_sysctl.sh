#!/bin/bash
python3 /mnt/d/桌面/star26-deps/scripts/_rcjobs_clean.py
echo "=== kernel build ==="
bash /mnt/d/桌面/star26-deps/scripts/build-star-native.sh > /tmp/kb.log 2>&1
echo "BUILD_EXIT=$?"
grep -c 'error:' /tmp/kb.log
grep -E 'OK __kalloc|PASS|BUILD' /tmp/kb.log | tail -3
</>
