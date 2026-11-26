#!/bin/bash
bash /mnt/d/桌面/star26-deps/scripts/build-star-native.sh > /tmp/kb8.log 2>&1
echo "BUILD_EXIT=$?"; grep -c 'error:' /tmp/kb8.log
cd /mnt/d/桌面/star26-deps/scripts
N=180 bash ./make-s139.sh 2>&1 | grep -E 'boot.img' | tail -1
sed 's/TAG=s131/TAG=s180/' _s131_flash.sh > _s180_flash.sh
python3 _patch_wait.py _s180_flash.sh
bash _s180_flash.sh
sleep 200
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
$F -s xnuloader oem log > /dev/null
$F -s xnuloader get_staged "C:/ios26/s180a.bin" > /dev/null
strings -n 5 /mnt/c/ios26/s180a.bin > /tmp/s180a.txt
echo "=== annibale-env injections ==="
grep -a 'annibale-env:' /tmp/s180a.txt | sort -u | head -20
echo "=== matched/thumbs ==="
echo "matched: $(grep -ac 'sync matched' /tmp/s180a.txt)  thumbs: $(grep -ac 'thumb [0-9]*:' /tmp/s180a.txt)"
</>
