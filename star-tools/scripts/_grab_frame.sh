#!/bin/bash
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
$F -s xnuloader oem screenshot > /dev/null 2>&1
$F -s xnuloader get_staged "C:/ios26/t6-frame.raw" > /dev/null 2>&1
python3 /mnt/d/桌面/star26-deps/scripts/fb2png.py /mnt/c/ios26/t6-frame.raw /mnt/c/ios26/t6-frame.png
ls -l /mnt/c/ios26/t6-frame.png