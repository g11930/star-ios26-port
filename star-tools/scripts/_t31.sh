#!/bin/bash
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
$F -s xnuloader oem log > /dev/null 2>&1
$F -s xnuloader get_staged "C:/ios26/s200c.bin" > /dev/null 2>&1
strings -n 5 /mnt/c/ios26/s200c.bin > /tmp/s200c.txt
echo "lines $(wc -l < /tmp/s200c.txt) last $(grep -a -oE '2025-12-[0-9]+ [0-9:.]+\+0800' /tmp/s200c.txt | tail -1)"
$F -s xnuloader oem screenshot > /dev/null 2>&1
$F -s xnuloader get_staged "C:/ios26/s200c-frame.raw" > /dev/null 2>&1
python3 /mnt/d/桌面/star26-deps/scripts/fb2png.py /mnt/c/ios26/s200c-frame.raw /mnt/c/ios26/s200c-frame.png > /dev/null 2>&1
ls -l /mnt/c/ios26/s200c-frame.png
echo "=== touch ==="; grep -a -iE 'goodix|STM frame|loopback|focaltech|fts|annibale-touch' /tmp/s200c.txt | head -20