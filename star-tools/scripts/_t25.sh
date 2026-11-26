#!/bin/bash
A=/mnt/d/桌面/adb-fastboot/adb.exe
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
IMG=C:/ios26/s191-boot.img
$F -s xnuloader oem stop > /dev/null 2>&1
for i in $(seq 1 70); do sleep 3; $A devices | grep -q "	device" && break; done
$A devices | head -2
$A reboot bootloader > /dev/null 2>&1
for i in $(seq 1 25); do sleep 2; $F devices | grep -q "	fastboot" && break; done
$F boot "$IMG" 2>&1 | tail -2 || { echo refused; exit 0; }
sleep 100
$F -s xnuloader oem log > /dev/null 2>&1
$F -s xnuloader get_staged "C:/ios26/s191c.bin" > /dev/null 2>&1
strings -n 5 /mnt/c/ios26/s191c.bin > /tmp/s191c.txt
echo "lines $(wc -l < /tmp/s191c.txt) last $(grep -a -oE '2025-12-[0-9]+ [0-9:.]+\+0800' /tmp/s191c.txt | tail -1)"
echo "=== touch ==="; grep -a -iE 'goodix|STM frame|loopback|focaltech|PANIC' /tmp/s191c.txt | head -30