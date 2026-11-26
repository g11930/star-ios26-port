#!/bin/bash
N=$1
bash /mnt/d/桌面/star26-deps/scripts/build-star-native.sh >/dev/null 2>&1
echo "errors: $(grep -c 'error:' /mnt/c/ios26/star-native-build.log)"
tail -1 /mnt/c/ios26/star-native-build.log
cd /mnt/d/桌面/star26-deps/scripts
N=$N bash ./make-s135.sh 2>&1 | grep 'boot.img' | tail -1
sed "s/TAG=s131/TAG=s${N}/" _s131_flash.sh > _s${N}_flash.sh
python3 _patch_wait.py _s${N}_flash.sh
bash _s${N}_flash.sh
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
$F -s xnuloader oem log > /dev/null
$F -s xnuloader get_staged "C:/ios26/s${N}d-live.bin" > /dev/null
strings -n 5 /mnt/c/ios26/s${N}d-live.bin > /tmp/s${N}.txt
echo "=== touch trace ==="
grep -a 'goodix\|annibale: input' /tmp/s${N}.txt | head -40
</>
