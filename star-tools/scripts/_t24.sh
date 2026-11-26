#!/bin/bash
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
sleep 90
$F -s xnuloader oem log > /dev/null 2>&1
$F -s xnuloader get_staged "C:/ios26/s191b.bin" > /dev/null 2>&1
strings -n 5 /mnt/c/ios26/s191b.bin > /tmp/s191b.txt
echo "lines $(wc -l < /tmp/s191b.txt) last $(grep -a -oE '2025-12-[0-9]+ [0-9:.]+\+0800' /tmp/s191b.txt | tail -1)"
echo "=== touch ==="; grep -a -iE 'goodix|STM frame|loopback|focaltech|fts' /tmp/s191b.txt | head -30
$F -s xnuloader oem screenshot > /dev/null 2>&1
$F -s xnuloader get_staged "C:/ios26/s191-frame.raw" > /dev/null 2>&1
python3 /mnt/d/桌面/star26-deps/scripts/fb2png.py /mnt/c/ios26/s191-frame.raw /mnt/c/ios26/s191-frame.png > /dev/null 2>&1
ls -l /mnt/c/ios26/s191-frame.png