#!/bin/bash
cd /mnt/d/桌面/star26-deps/scripts
sed 's/TAG=s131/TAG=s172/' _s131_flash.sh > _s172_flash.sh
python3 _patch_wait.py _s172_flash.sh
bash _s172_flash.sh
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
$F -s xnuloader oem log > /dev/null
$F -s xnuloader get_staged "C:/ios26/s172d-live.bin" > /dev/null
strings -n 5 /mnt/c/ios26/s172d-live.bin > /tmp/s172.txt
echo "=== rc.jobs execution ==="
grep -a -E 'trialwake|metal_props|triangle_app|rc.jobs|annibale: demo' /tmp/s172.txt | head -12
echo "=== leftover taps (should be none) ==="
grep -a -c 'anntouch: all' /tmp/s172.txt
grep -a 'anntouch' /tmp/s172.txt | head -6
</>
