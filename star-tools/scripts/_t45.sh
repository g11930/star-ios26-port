#!/bin/bash
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
$F -s xnuloader oem log > /dev/null 2>&1
$F -s xnuloader get_staged "C:/ios26/s200d.bin" > /dev/null 2>&1
strings -n 5 /mnt/c/ios26/s200d.bin > /tmp/s200d.txt
echo "lines $(wc -l < /tmp/s200d.txt) last $(grep -a -oE '2025-12-[0-9]+ [0-9:.]+\+0800' /tmp/s200d.txt | tail -1)"
grep -a 'PANIC' /tmp/s200d.txt | head -3
$F -s xnuloader oem screenshot > /dev/null 2>&1
$F -s xnuloader get_staged "C:/ios26/s200d-frame.raw" > /dev/null 2>&1
python3 /mnt/d/桌面/star26-deps/scripts/fb2png.py /mnt/c/ios26/s200d-frame.raw /mnt/c/ios26/s200d-frame.png > /dev/null 2>&1
ls -l /mnt/c/ios26/s200d-frame.png