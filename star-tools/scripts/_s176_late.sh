#!/bin/bash
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
$F -s xnuloader oem log > /dev/null
$F -s xnuloader get_staged "C:/ios26/s176e.bin" > /dev/null
strings -n 5 /mnt/c/ios26/s176e.bin > /tmp/s176e.txt
echo "=== thumbs ==="
grep -ac 'thumb [0-9]*:' /tmp/s176e.txt
grep -a 'thumb [0-9]*:' /tmp/s176e.txt | head -8
echo "=== env ==="
grep -a 'kern.annibale.env' /tmp/s176e.txt | head -6
echo "=== last timestamp ==="
grep -a -oE '2025-12-10 [0-9:.]+\+0800' /tmp/s176e.txt | tail -2
echo "=== screen ==="
$F -s xnuloader oem screenshot > /dev/null
$F -s xnuloader get_staged "C:/ios26/s176e-frame.raw" > /dev/null
python3 /mnt/d/桌面/star26-deps/scripts/fb2png.py /mnt/c/ios26/s176e-frame.raw /mnt/c/ios26/s176e-frame.png
ls -l /mnt/c/ios26/s176e-frame.png
</>
