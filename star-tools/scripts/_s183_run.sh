#!/bin/bash
bash /mnt/d/桌面/star26-deps/scripts/build-star-native.sh > /tmp/kb11.log 2>&1
echo "BUILD_EXIT=$?"; grep -c 'error:' /tmp/kb11.log
cd /mnt/d/桌面/star26-deps/scripts
N=183 bash ./make-s139.sh 2>&1 | grep -E 'boot.img' | tail -1
A=/mnt/d/桌面/adb-fastboot/adb.exe
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
$A reboot bootloader
for i in $(seq 1 20); do sleep 2; $F devices | grep -q fastboot && break; done
$F boot "C:/ios26/s183-boot.img"
sleep 260
$F -s xnuloader oem log > /dev/null
$F -s xnuloader get_staged "C:/ios26/s183a.bin" > /dev/null
strings -n 5 /mnt/c/ios26/s183a.bin > /tmp/s183a.txt
echo "=== injections ==="; grep -a 'annibale-env:' /tmp/s183a.txt | sort -u | head -12
echo "=== thumbs ==="; echo "thumbs: $(grep -ac 'thumb [0-9]*:' /tmp/s183a.txt) groups: $(grep -ac 'thumb group' /tmp/s183a.txt)"
grep -a 'thumb [0-9]*:' /tmp/s183a.txt | head -8
echo "last ts: $(grep -a -oE '2025-12-10 [0-9:.]+\+0800' /tmp/s183a.txt | tail -1)"
</>
