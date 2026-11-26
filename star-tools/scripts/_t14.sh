#!/bin/bash
A=/mnt/d/桌面/adb-fastboot/adb.exe
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
echo "=== state before ==="
$F devices; $A devices | head -3
echo "=== grab loader log first ==="
$F -s xnuloader oem log > /dev/null 2>&1
$F -s xnuloader get_staged "C:/ios26/s190crash.bin" > /dev/null 2>&1
strings -n 5 /mnt/c/ios26/s190crash.bin > /tmp/s190crash.txt
echo "lines $(wc -l < /tmp/s190crash.txt)"
tail -25 /tmp/s190crash.txt
echo "=== frame ==="
$F -s xnuloader oem screenshot > /dev/null 2>&1
$F -s xnuloader get_staged "C:/ios26/s190crash-frame.raw" > /dev/null 2>&1
python3 /mnt/d/桌面/star26-deps/scripts/fb2png.py /mnt/c/ios26/s190crash-frame.raw /mnt/c/ios26/s190crash-frame.png > /dev/null 2>&1
ls -l /mnt/c/ios26/s190crash-frame.png 2>/dev/null