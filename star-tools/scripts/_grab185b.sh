#!/bin/bash
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
sleep 90
$F -s xnuloader oem log > /dev/null 2>&1
$F -s xnuloader get_staged "C:/ios26/s185c.bin" > /dev/null 2>&1
strings -n 5 /mnt/c/ios26/s185c.bin > /tmp/s185c.txt
echo "lines: $(wc -l < /tmp/s185c.txt)  last: $(grep -a -oE '2025-12-10 [0-9:.]+\+0800' /tmp/s185c.txt | tail -1)"
echo "thumbs: $(grep -ac 'thumb [0-9]*:' /tmp/s185c.txt) groups: $(grep -ac 'thumb group' /tmp/s185c.txt)"
echo "injections:"; grep -a 'annibale-env:' /tmp/s185c.txt | sort -u | head -8
$F -s xnuloader oem screenshot > /dev/null 2>&1
$F -s xnuloader get_staged "C:/ios26/s185c-frame.raw" > /dev/null 2>&1
python3 /mnt/d/桌面/star26-deps/scripts/fb2png.py /mnt/c/ios26/s185c-frame.raw /mnt/c/ios26/s185c-frame.png
ls -l /mnt/c/ios26/s185c-frame.png