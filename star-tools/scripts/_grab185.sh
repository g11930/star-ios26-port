#!/bin/bash
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
$F -s xnuloader oem log > /dev/null 2>&1
$F -s xnuloader get_staged "C:/ios26/s185b.bin" > /dev/null 2>&1
strings -n 5 /mnt/c/ios26/s185b.bin > /tmp/s185b.txt
echo "lines: $(wc -l < /tmp/s185b.txt)  last: $(grep -a -oE '2025-12-10 [0-9:.]+\+0800' /tmp/s185b.txt | tail -1)"
echo "thumbs: $(grep -ac 'thumb [0-9]*:' /tmp/s185b.txt)  groups: $(grep -ac 'thumb group' /tmp/s185b.txt)"
grep -a 'thumb [0-9]*:' /tmp/s185b.txt | head -5
echo "=== injections ==="
grep -a 'annibale-env:' /tmp/s185b.txt | sort -u | head -12