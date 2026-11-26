#!/bin/bash
A=/mnt/d/桌面/adb-fastboot/adb.exe
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
IMG=${IMG:-C:/ios26/s210-boot.img}
timeout 10 $F -s xnuloader reboot > /dev/null 2>&1
for i in $(seq 1 30); do sleep 4; $A devices | grep -q "	device" && break; done
if $A devices | grep -q "	device"; then
  $A reboot bootloader > /dev/null 2>&1
  for i in $(seq 1 30); do sleep 2; $F devices | grep -q "	fastboot" && break; done
fi
echo "abl: $($F devices | head -1)"
timeout 20 $F boot "$IMG" 2>&1 | tail -1
for k in 1 2 3 4; do
  sleep 90
  $F -s xnuloader oem screenshot > /dev/null 2>&1
  $F -s xnuloader get_staged "C:/ios26/ab-frame.raw" > /dev/null 2>&1
  python3 /mnt/d/桌面/star26-deps/scripts/fb2png.py /mnt/c/ios26/ab-frame.raw /mnt/c/ios26/ab-frame.png > /dev/null 2>&1
  s=$(stat -c %s /mnt/c/ios26/ab-frame.png)
  echo "T+$((k*90))s png=$s"
  cp /mnt/c/ios26/ab-frame.png "/mnt/c/ios26/ab-$k.png"
  [ "$s" -gt 600000 ] && { echo "DESKTOP at T+$((k*90))s"; break; }
done