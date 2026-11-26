#!/bin/bash
cd /mnt/d/桌面/star26-deps/scripts
sed 's/TAG=s131/TAG=s178/' _s131_flash.sh > _s178_flash.sh
python3 _patch_wait.py _s178_flash.sh
bash _s178_flash.sh
sleep 240
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
$F -s xnuloader oem log > /dev/null
$F -s xnuloader get_staged "C:/ios26/s178a.bin" > /dev/null
strings -n 5 /mnt/c/ios26/s178a.bin > /tmp/s178a.txt
echo "=== matched lines ==="
grep -a 'sync matched' /tmp/s178a.txt | head -6
echo "=== thumb headers ==="
grep -a 'thumb [0-9]*:' /tmp/s178a.txt | head -8
echo "=== thumb groups ==="
grep -a 'thumb group' /tmp/s178a.txt | head -6
echo "=== screen ==="
$F -s xnuloader oem screenshot > /dev/null
$F -s xnuloader get_staged "C:/ios26/s178a-frame.raw" > /dev/null
python3 fb2png.py /mnt/c/ios26/s178a-frame.raw /mnt/c/ios26/s178a-frame.png
ls -l /mnt/c/ios26/s178a-frame.png
</>
