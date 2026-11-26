#!/bin/bash
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
echo "=== s208c 87-line log ==="
strings -n 5 /mnt/c/ios26/s208c.bin | head -40 | cut -c1-160
echo "=== screenshot ==="
$F -s xnuloader oem screenshot > /dev/null 2>&1
$F -s xnuloader get_staged "C:/ios26/s208c-frame.raw" > /dev/null 2>&1
python3 /mnt/d/桌面/star26-deps/scripts/fb2png.py /mnt/c/ios26/s208c-frame.raw /mnt/c/ios26/s208c-frame.png > /dev/null 2>&1
ls -l /mnt/c/ios26/s208c-frame.png | awk '{print $5}'