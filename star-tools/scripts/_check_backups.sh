#!/bin/bash
echo "=== s175 backup ==="
ls -l /mnt/d/桌面/star26-deps/backup/20261118-s175-mesa-cache/ 2>/dev/null
echo "=== s171 backup kernel files ==="
ls -l /mnt/d/桌面/star26-deps/backup/20261118-s171-blackicons/ 2>/dev/null | head -12
echo "=== does s171 kern_exec have namematches? ==="
grep -c 'namematches' /mnt/d/桌面/star26-deps/backup/20261118-s171-blackicons/kern_exec.c 2>/dev/null
echo "=== s175 image ==="
ls -l /mnt/c/ios26/s175-boot.img /mnt/d/桌面/star26-deps/backup/20261118-s175-mesa-cache/s175-boot.img 2>/dev/null