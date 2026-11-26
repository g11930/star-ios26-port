#!/bin/bash
cd /root/star26/star-native || exit 1
git --no-pager diff --stat
echo "=== kern_exec ==="
git --no-pager diff bsd/kern/kern_exec.c | head -80
echo "=== kern_minimac ==="
git --no-pager diff bsd/kern/kern_minimac.c | head -60
echo "=== sleh ==="
git --no-pager diff osfmk/arm64/sleh.c | head -60