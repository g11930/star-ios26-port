#!/bin/bash
SRC=/root/star26/star-native
wsl.exe -d Ubuntu-24.04 bash -c "
echo '=== [1] kern_cs.c star_cs_keep_valid 逻辑 (85-115, 290-345) ==='
sed -n '85,115p' $SRC/bsd/kern/kern_cs.c
echo '--- 290-345 ---'
sed -n '290,345p' $SRC/bsd/kern/kern_cs.c
echo
echo '=== [2] 各镜像 cmdline 是否含 star_cs_keep_valid ==='
for f in /mnt/c/ios26/s205-boot.img /mnt/c/ios26/s208-boot.img /mnt/c/ios26/s210-boot.img /mnt/c/ios26/s211-boot.img; do
  echo \"--- \$f ---\"
  strings \$f 2>/dev/null | grep -oE 'star_cs_keep_valid[= ]?[0-9]*' | head -3
  strings \$f 2>/dev/null | grep -oE 'autounlock[= ][0-9]*' | head -2
done
" 2>/dev/null | tr -d '\r'
