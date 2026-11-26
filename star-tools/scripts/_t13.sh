#!/bin/bash
A=/mnt/d/桌面/adb-fastboot/adb.exe
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
IMG=C:/ios26/s190-boot.img
$F -s xnuloader oem stop > /dev/null 2>&1
for i in $(seq 1 70); do sleep 3; $A devices | grep -q "	device" && break; done
$A devices | head -2
$A reboot bootloader > /dev/null 2>&1
for i in $(seq 1 25); do sleep 2; $F devices | grep -q "	fastboot" && break; done
$F boot "$IMG" 2>&1 | tail -2 || { echo refused; exit 0; }
sleep 150
$F -s xnuloader oem log > /dev/null 2>&1
$F -s xnuloader get_staged "C:/ios26/s190a.bin" > /dev/null 2>&1
strings -n 5 /mnt/c/ios26/s190a.bin > /tmp/s190a.txt
echo "=== clock/serial engine ==="; grep -a 'clocks\|serial engine\|SPI transfer\|by hand\|failure dump' /tmp/s190a.txt | head -10
echo "=== focaltech ==="; grep -a 'focaltech' /tmp/s190a.txt | head -10
echo "=== ts ==="; grep -a -oE '2025-12-10 [0-9:.]+\+0800' /tmp/s190a.txt | tail -1