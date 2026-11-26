#!/bin/bash
A=/mnt/d/桌面/adb-fastboot/adb.exe
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
IMG=${IMG:-C:/ios26/s212-boot.img}
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
  $F -s xnuloader oem log > /dev/null 2>&1
  $F -s xnuloader get_staged "C:/ios26/s212.bin" > /dev/null 2>&1
  strings -n 5 /mnt/c/ios26/s212.bin > /tmp/s212.txt
  $F -s xnuloader oem screenshot > /dev/null 2>&1
  $F -s xnuloader get_staged "C:/ios26/s212-frame.raw" > /dev/null 2>&1
  python3 /mnt/d/桌面/star26-deps/scripts/fb2png.py /mnt/c/ios26/s212-frame.raw /mnt/c/ios26/s212-frame.png > /dev/null 2>&1
  s=$(stat -c %s /mnt/c/ios26/s212-frame.png)
  echo "T+$((k*90))s png=$s lines=$(wc -l < /tmp/s212.txt) stats=$(grep -ac 'frames in' /tmp/s212.txt)"
  [ "$s" -gt 600000 ] && { echo "DESKTOP at T+$((k*90))s"; cp /mnt/c/ios26/s212-frame.png /mnt/c/ios26/s212-desktop.png; grep -a 'frames in' /tmp/s212.txt | tail -3; break; }
done