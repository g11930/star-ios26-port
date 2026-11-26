#!/bin/bash
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
A=/mnt/d/桌面/adb-fastboot/adb.exe
echo "state:"; $F devices; $A devices | head -2
echo "--- boot s182 (last known good)"
$F -s xnuloader boot "C:/ios26/s182-boot.img" 2>&1 | tail -2
sleep 120
$F -s xnuloader oem log > /dev/null 2>&1
$F -s xnuloader get_staged "C:/ios26/after182.bin" > /dev/null 2>&1
strings -n 5 /mnt/c/ios26/after182.bin > /tmp/after182.txt
echo "lines: $(wc -l < /tmp/after182.txt)  last: $(grep -a -oE '2025-12-10 [0-9:.]+\+0800' /tmp/after182.txt | tail -1)"
grep -a 'PANIC\|panic' /tmp/after182.txt | head -3