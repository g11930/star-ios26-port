#!/bin/bash
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
A=/mnt/d/桌面/adb-fastboot/adb.exe
echo "fb: $($F devices | head -1) adb: $($A devices | awk 'NR==2{print $2}')"
sleep 100
$F -s xnuloader oem log > /dev/null 2>&1
$F -s xnuloader get_staged "C:/ios26/s208e.bin" > /dev/null 2>&1
strings -n 5 /mnt/c/ios26/s208e.bin > /tmp/s208e.txt
echo "lines=$(wc -l < /tmp/s208e.txt) panic=$(grep -ac PANIC /tmp/s208e.txt) stats=$(grep -ac 'frames in' /tmp/s208e.txt) sb=$(grep -ac 'SpringBoard 33' /tmp/s208e.txt)"
grep -a 'PANIC caller' /tmp/s208e.txt | head -1 | cut -c1-110
grep -a 'frames in' /tmp/s208e.txt | tail -4
$F -s xnuloader oem screenshot > /dev/null 2>&1
$F -s xnuloader get_staged "C:/ios26/s208e-frame.raw" > /dev/null 2>&1
python3 /mnt/d/桌面/star26-deps/scripts/fb2png.py /mnt/c/ios26/s208e-frame.raw /mnt/c/ios26/s208e-frame.png > /dev/null 2>&1
ls -l /mnt/c/ios26/s208e-frame.png | awk '{print "png", $5}'