#!/bin/bash
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
A=/mnt/d/桌面/adb-fastboot/adb.exe
echo "fb: $($F devices | head -1)  adb: $($A devices | awk 'NR==2{print $2}')"
$F -s xnuloader oem log > /dev/null 2>&1
$F -s xnuloader get_staged "C:/ios26/s201crash.bin" > /dev/null 2>&1
strings -n 5 /mnt/c/ios26/s201crash.bin > /tmp/s201crash.txt
echo "lines $(wc -l < /tmp/s201crash.txt)"
grep -a 'PANIC\|panic' /tmp/s201crash.txt | head -4
$F -s xnuloader oem screenshot > /dev/null 2>&1
$F -s xnuloader get_staged "C:/ios26/s201crash-frame.raw" > /dev/null 2>&1
python3 /mnt/d/桌面/star26-deps/scripts/fb2png.py /mnt/c/ios26/s201crash-frame.raw /mnt/c/ios26/s201crash-frame.png > /dev/null 2>&1
ls -l /mnt/c/ios26/s201crash-frame.png