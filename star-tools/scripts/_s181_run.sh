#!/bin/bash
bash /mnt/d/桌面/star26-deps/scripts/build-star-native.sh > /tmp/kb9.log 2>&1
echo "BUILD_EXIT=$?"; grep -c 'error:' /tmp/kb9.log; grep -E 'error:' /tmp/kb9.log | head -3
cd /mnt/d/桌面/star26-deps/scripts
N=181 bash ./make-s139.sh 2>&1 | grep -E 'boot.img' | tail -1
sed 's/TAG=s131/TAG=s181/' _s131_flash.sh > _s181_flash.sh
python3 _patch_wait.py _s181_flash.sh
bash _s181_flash.sh
sleep 200
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
$F -s xnuloader oem log > /dev/null
$F -s xnuloader get_staged "C:/ios26/s181a.bin" > /dev/null
strings -n 5 /mnt/c/ios26/s181a.bin > /tmp/s181a.txt
echo "=== injection notes ==="
grep -a 'annibale-env:' /tmp/s181a.txt | sort -u | head -20
echo "=== matched/thumbs ==="
echo "matched: $(grep -ac 'sync matched' /tmp/s181a.txt)  thumbs: $(grep -ac 'thumb [0-9]*:' /tmp/s181a.txt)"
</>
