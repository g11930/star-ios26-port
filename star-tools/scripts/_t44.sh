#!/bin/bash
A=/mnt/d/桌面/adb-fastboot/adb.exe
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
IMG=${IMG:-C:/ios26/s200-boot.img}
# degraded loader: reboot brings Android back
timeout 10 $F -s xnuloader reboot > /dev/null 2>&1
for i in $(seq 1 24); do sleep 5; $A devices | grep -q "	device" && break; done
echo "adb: $($A devices | awk 'NR==2{print $2}')"
$A reboot bootloader > /dev/null 2>&1
for i in $(seq 1 25); do sleep 2; $F devices | grep -q "	fastboot" && break; done
echo "fb: $($F devices | head -1)"
$F boot "$IMG" 2>&1 | tail -2 || { echo refused; exit 0; }
for i in $(seq 1 6); do
  sleep 60
  $F -s xnuloader oem screenshot > /dev/null 2>&1
  $F -s xnuloader get_staged "C:/ios26/verify-frame.raw" > /dev/null 2>&1
  python3 /mnt/d/桌面/star26-deps/scripts/fb2png.py /mnt/c/ios26/verify-frame.raw /mnt/c/ios26/verify-frame.png > /dev/null 2>&1
  echo "T+$((i*60))s png=$(stat -c %s /mnt/c/ios26/verify-frame.png)"
  s=$(stat -c %s /mnt/c/ios26/verify-frame.png)
  [ "$s" -gt 100000 ] && [ "$s" -lt 380000 ] && { cp /mnt/c/ios26/verify-frame.png /mnt/c/ios26/desktop-$i.png; echo "desktop at T+$((i*60))s"; }
done