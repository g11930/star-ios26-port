#!/bin/bash
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
A=/mnt/d/桌面/adb-fastboot/adb.exe
echo "fb: $($F devices | head -1)  adb: $($A devices | awk 'NR==2{print $2}')"
$F -s xnuloader oem log > /dev/null 2>&1
$F -s xnuloader get_staged "C:/ios26/s208b.bin" > /dev/null 2>&1
strings -n 5 /mnt/c/ios26/s208b.bin > /tmp/s208b.txt
echo "lines $(wc -l < /tmp/s208b.txt)"
grep -a 'cmdline:' /tmp/s208b.txt | head -1 | tail -c 120
grep -a -oE '2025-12-[0-9]+ [0-9:.]+\+0800' /tmp/s208b.txt | tail -1
echo "=== frame stats ==="
grep -a 'frames in' /tmp/s208b.txt | tail -8
echo "=== panic ==="
grep -a 'PANIC' /tmp/s208b.txt | head -2
$F -s xnuloader oem screenshot > /dev/null 2>&1
$F -s xnuloader get_staged "C:/ios26/s208b-frame.raw" > /dev/null 2>&1
python3 /mnt/d/桌面/star26-deps/scripts/fb2png.py /mnt/c/ios26/s208b-frame.raw /mnt/c/ios26/s208b-frame.png > /dev/null 2>&1
ls -l /mnt/c/ios26/s208b-frame.png 2>/dev/null | awk '{print "png", $5}'