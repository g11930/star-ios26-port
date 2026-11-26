#!/bin/bash
cd /root/star26/star-native || exit 1
echo "=== git status ==="
git status --short 2>/dev/null | head -30
echo "=== recent commits ==="
git log --oneline -5 2>/dev/null
echo "=== kernel part timestamps ==="
ls -l --time-style=+%F_%T /root/star26/s111/parts/kernel /root/star26/s111/parts/kernel.pre-gpu 2>/dev/null
echo "=== images ==="
ls -l --time-style=+%F_%T /mnt/c/ios26/s200-boot.img /mnt/c/ios26/s208-boot.img /mnt/c/ios26/s209-boot.img 2>/dev/null | awk '{print $5, $6, $7}'