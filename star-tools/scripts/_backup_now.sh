#!/bin/bash
set -e
B=/mnt/d/桌面/star26-deps/backup/20261118-s171-blackicons
mkdir -p $B/kernel $B/scripts $B/images $B/logs
cd /root/star26/star-native
cp bsd/dev/star/annibale_goodix.c bsd/dev/star/annibale_focaltech_fw.h bsd/dev/star/annibale_input.c \
   bsd/dev/star/annibale_adreno.c bsd/conf/files $B/kernel/ 2>/dev/null
cp bsd/sys/annibale_input.h $B/kernel/ 2>/dev/null
cp /mnt/d/桌面/star26-deps/scripts/*.sh /mnt/d/桌面/star26-deps/scripts/*.py $B/scripts/ 2>/dev/null
cp /mnt/c/ios26/s171-boot.img /mnt/c/ios26/s170-boot.img $B/images/ 2>/dev/null
cp /mnt/c/ios26/s171d-live.bin $B/logs/ 2>/dev/null
cp /mnt/c/ios26/s171c-frame.raw $B/images/ 2>/dev/null
ls -la $B/kernel $B/images | head -20
du -sh $B
</>
