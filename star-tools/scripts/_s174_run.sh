#!/bin/bash
cd /mnt/d/桌面/star26-deps/scripts
sed 's/TAG=s131/TAG=s174/' _s131_flash.sh > _s174_flash.sh
python3 _patch_wait.py _s174_flash.sh
bash _s174_flash.sh
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
grab() {
  name=$1
  $F -s xnuloader oem log > /dev/null
  $F -s xnuloader get_staged "C:/ios26/$name.bin" > /dev/null
  strings -n 5 /mnt/c/ios26/$name.bin > /tmp/$name.txt
}
grab s174d
echo "=== boot1 env applied ==="
grep -a 'kern.annibale.env' /tmp/s174d.txt | head -4
echo "=== boot1 ir3 waits ==="
grep -ac 'ir3 wait' /tmp/s174d.txt
echo "=== reboot for boot2 ==="
$F -s xnuloader reboot bootloader
sleep 15
$F -s xnuloader boot "C:/ios26/s174-boot.img"
sleep 100
grab s174e
echo "=== boot2 env applied ==="
grep -a 'kern.annibale.env' /tmp/s174e.txt | head -4
echo "=== boot2 ir3 waits ==="
grep -ac 'ir3 wait' /tmp/s174e.txt
grep -a 'ir3 wait' /tmp/s174e.txt | tail -5
</>
