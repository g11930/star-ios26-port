#!/bin/bash
K=/root/star26/warsaw-ref/userland/src/inject_sb26.c
sed -n '786,1062p' "$K" > /mnt/c/ios26/k90_shim_full.txt
echo "exported $(wc -l < /mnt/c/ios26/k90_shim_full.txt) lines"
echo "=== ramdisk rebuild toolchain (star) ==="
grep -n 'root.apfs\|ramdisk\|mkfs.apfs\|apfs' /root/star26/hackios-xnu-userland/userland/build.sh | tail -30
echo "=== repack-ramdisk.sh logic (how ramdisk <-> root.apfs) ==="
cat /mnt/d/桌面/star26-deps/scripts/repack-ramdisk.sh 2>/dev/null | head -40
