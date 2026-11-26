#!/bin/bash
A=/mnt/d/桌面/adb-fastboot/adb.exe
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
IMG=C:/ios26/s189-boot.img
$F -s xnuloader oem stop > /dev/null 2>&1
for i in $(seq 1 70); do sleep 3; $A devices | grep -q "	device" && break; done
$A devices | head -2
$A reboot bootloader > /dev/null 2>&1
for i in $(seq 1 25); do sleep 2; $F devices | grep -q "	fastboot" && break; done
$F devices | head -1
$F boot "$IMG" 2>&1 | tail -2 || { echo refused; exit 0; }
sleep 150
$F -s xnuloader oem log > /dev/null 2>&1
$F -s xnuloader get_staged "C:/ios26/s189a.bin" > /dev/null 2>&1
strings -n 5 /mnt/c/ios26/s189a.bin > /tmp/s189a.txt
echo "=== lines ==="; grep -a 'goodix: lines' /tmp/s189a.txt
echo "=== focaltech ==="; grep -a 'focaltech\|no focaltech\|touch screen' /tmp/s189a.txt | head -12
echo "=== ts ==="; grep -a -oE '2025-12-10 [0-9:.]+\+0800' /tmp/s189a.txt | tail -1