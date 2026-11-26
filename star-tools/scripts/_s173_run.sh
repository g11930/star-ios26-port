#!/bin/bash
cd /mnt/d/桌面/star26-deps/scripts
sed 's/TAG=s131/TAG=s173/' _s131_flash.sh > _s173_flash.sh
python3 _patch_wait.py _s173_flash.sh
bash _s173_flash.sh
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
$F -s xnuloader oem log > /dev/null
$F -s xnuloader get_staged "C:/ios26/s173d-live.bin" > /dev/null
strings -n 5 /mnt/c/ios26/s173d-live.bin > /tmp/s173.txt
echo "=== env applied ==="
grep -a 'kern.annibale.env' /tmp/s173.txt | head -6
echo "=== ir3 waits after restart ==="
grep -a 'ir3 wait' /tmp/s173.txt | tail -8
echo "=== cache dir ==="
grep -a -i 'mesa-annibale\|shader cache' /tmp/s173.txt | head -6
</>
