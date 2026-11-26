#!/bin/bash
A=/mnt/d/桌面/adb-fastboot/adb.exe
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
IMG=C:/ios26/s208-boot.img
if $A devices | grep -q "	device"; then
  $A reboot bootloader > /dev/null 2>&1
  for i in $(seq 1 30); do sleep 2; $F devices | grep -q "	fastboot" && break; done
fi
echo "abl: $($F devices | head -1)"
timeout 20 $F boot "$IMG" 2>&1 | tail -1
sleep 100
$F -s xnuloader oem log > /dev/null 2>&1
$F -s xnuloader get_staged "C:/ios26/s208d.bin" > /dev/null 2>&1
strings -n 5 /mnt/c/ios26/s208d.bin > /tmp/s208d.txt
echo "T+100s lines=$(wc -l < /tmp/s208d.txt) panic=$(grep -ac 'PANIC' /tmp/s208d.txt) stats=$(grep -ac 'frames in' /tmp/s208d.txt)"
grep -a 'PANIC caller' /tmp/s208d.txt | head -1 | cut -c1-120
grep -a 'frames in' /tmp/s208d.txt | tail -3