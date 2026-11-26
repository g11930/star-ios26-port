#!/bin/bash
A=/mnt/d/桌面/adb-fastboot/adb.exe
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
IMG=C:/ios26/s191-boot.img
$A devices | head -3
$A reboot bootloader > /dev/null 2>&1
for i in $(seq 1 25); do sleep 2; $F devices | grep -q "	fastboot" && break; done
$F devices | head -1
$F boot "$IMG" 2>&1 | tail -2 || { echo refused; exit 0; }
sleep 60
$F -s xnuloader oem log > /dev/null 2>&1
$F -s xnuloader get_staged "C:/ios26/s191a.bin" > /dev/null 2>&1
strings -n 5 /mnt/c/ios26/s191a.bin > /tmp/s191a.txt
echo "lines $(wc -l < /tmp/s191a.txt)"
echo "=== touch ==="
grep -a -iE 'goodix|STM frame|loopback|touch|fts' /tmp/s191a.txt | head -40