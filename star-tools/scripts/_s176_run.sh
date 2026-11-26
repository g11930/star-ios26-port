#!/bin/bash
cd /mnt/d/桌面/star26-deps/scripts
sed 's/TAG=s131/TAG=s176/' _s131_flash.sh > _s176_flash.sh
python3 _patch_wait.py _s176_flash.sh
bash _s176_flash.sh
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
$F -s xnuloader oem log > /dev/null
$F -s xnuloader get_staged "C:/ios26/s176d.bin" > /dev/null
strings -n 5 /mnt/c/ios26/s176d.bin > /tmp/s176d.txt
echo "=== thumb headers ==="
grep -a 'thumb [0-9]*:' /tmp/s176d.txt | head -12
echo "=== count ==="
grep -ac 'thumb [0-9]*:' /tmp/s176d.txt
</>
