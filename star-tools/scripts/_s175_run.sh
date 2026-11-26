#!/bin/bash
cd /mnt/d/桌面/star26-deps/scripts
sed 's/TAG=s131/TAG=s175/' _s131_flash.sh > _s175_flash.sh
python3 _patch_wait.py _s175_flash.sh
bash _s175_flash.sh
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
$F -s xnuloader oem log > /dev/null
$F -s xnuloader get_staged "C:/ios26/s175d.bin" > /dev/null
strings -n 5 /mnt/c/ios26/s175d.bin > /tmp/s175d.txt
echo "=== panic? ==="
grep -a -c 'PANIC' /tmp/s175d.txt
echo "=== env sysctl applied ==="
grep -a 'kern.annibale.env' /tmp/s175d.txt | head -5
echo "=== ir3 waits ==="
grep -ac 'ir3 wait' /tmp/s175d.txt
grep -a 'ir3 wait' /tmp/s175d.txt | tail -4
</>
