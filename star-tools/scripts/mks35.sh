#!/bin/bash
# mks35.sh -- s35: s34's kernel and cmdline, boot volume with OS_ACTIVITY_DT_MODE=YES
set -e
cd /root/star26/s34/work
python3 /mnt/d/桌面/star26-deps/scripts/stage27-oslog-console.py /root/star26/s34/work/root
python3 /root/star26/hackios-xnu-userland/tools/apfs/mkapfs.py -z --plain fw \
	-o /root/star26/s35/root.apfs annibale=root 2>&1 | tail -2
cd /root/star26/star-native
python3 /mnt/d/桌面/star26-deps/scripts/make-boot.py s35 s34 "" 2>&1 | tail -4
bash /mnt/d/桌面/star26-deps/scripts/repack-ramdisk.sh s35 2>&1 | tail -6
