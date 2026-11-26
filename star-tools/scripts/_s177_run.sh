#!/bin/bash
cd /mnt/d/桌面/star26-deps/scripts
sed 's/TAG=s131/TAG=s177/' _s131_flash.sh > _s177_flash.sh
python3 _patch_wait.py _s177_flash.sh
bash _s177_flash.sh
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
$A=; 
grab() { $F -s xnuloader oem log > /dev/null; $F -s xnuloader get_staged "C:/ios26/$1.bin" > /dev/null; strings -n 5 /mnt/c/ios26/$1.bin > /tmp/$1.txt; }
grab s177a_log
echo "=== thumbs so far ==="
grep -ac 'thumb [0-9]*:' /tmp/s177a_log.txt
sleep 150
grab s177b_log
echo "=== thumbs ==="
grep -ac 'thumb [0-9]*:' /tmp/s177b_log.txt
grep -a 'thumb [0-9]*:' /tmp/s177b_log.txt | head -10
echo "=== screen ==="
$F -s xnuloader oem screenshot > /dev/null
$F -s xnuloader get_staged "C:/ios26/s177-frame.raw" > /dev/null
python3 fb2png.py /mnt/c/ios26/s177-frame.raw /mnt/c/ios26/s177-frame.png
ls -l /mnt/c/ios26/s177-frame.png
</>
