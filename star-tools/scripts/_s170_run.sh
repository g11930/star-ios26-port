#!/bin/bash
cd /mnt/d/桌面/star26-deps/scripts
sed 's/TAG=s131/TAG=s170/' _s131_flash.sh > _s170_flash.sh
python3 _patch_wait.py _s170_flash.sh
bash _s170_flash.sh
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
$F -s xnuloader oem log > /dev/null
$F -s xnuloader get_staged "C:/ios26/s170d-live.bin" > /dev/null
strings -n 5 /mnt/c/ios26/s170d-live.bin > /tmp/s170.txt
echo "=== goodix trace ==="
grep -a 'goodix' /tmp/s170.txt | head -40
</>
