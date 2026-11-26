#!/bin/bash
cd /mnt/d/桌面/star26-deps/scripts
sed 's/TAG=s131/TAG=s179/' _s131_flash.sh > _s179_flash.sh
python3 _patch_wait.py _s179_flash.sh
bash _s179_flash.sh
echo "=== post: waiting for desktop ==="
sleep 230
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
$F -s xnuloader oem log > /dev/null
$F -s xnuloader get_staged "C:/ios26/s179a.bin" > /dev/null
strings -n 5 /mnt/c/ios26/s179a.bin > /tmp/s179a.txt
echo "matched: $(grep -ac 'sync matched' /tmp/s179a.txt)  thumbs: $(grep -ac 'thumb [0-9]*:' /tmp/s179a.txt)"
grep -a 'sync matched' /tmp/s179a.txt | head -4
grep -a 'thumb [0-9]*:' /tmp/s179a.txt | head -6
echo "last ts: $(grep -a -oE '2025-12-10 [0-9:.]+\+0800' /tmp/s179a.txt | tail -1)"
</>
