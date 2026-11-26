#!/bin/bash
sleep 180
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
$F -s xnuloader oem log > /dev/null
$F -s xnuloader get_staged "C:/ios26/s176g.bin" > /dev/null
strings -n 5 /mnt/c/ios26/s176g.bin > /tmp/s176g.txt
echo "=== last ts ==="
grep -a -oE '2025-12-10 [0-9:.]+\+0800' /tmp/s176g.txt | tail -1
echo "=== thumbs ==="
grep -ac 'thumb [0-9]*:' /tmp/s176g.txt
grep -a 'thumb [0-9]*:' /tmp/s176g.txt | head -6
echo "=== screen ==="
$F -s xnuloader oem screenshot > /dev/null
$F -s xnuloader get_staged "C:/ios26/s176g-frame.raw" > /dev/null
python3 /mnt/d/桌面/star26-deps/scripts/fb2png.py /mnt/c/ios26/s176g-frame.raw /mnt/c/ios26/s176g-frame.png
ls -l /mnt/c/ios26/s176g-frame.png
</>
