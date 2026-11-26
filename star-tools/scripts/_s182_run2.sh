#!/bin/bash
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
$F -s xnuloader oem stop
sleep 5
$F -s xnuloader boot "C:/ios26/s182-boot.img"
sleep 240
$F -s xnuloader oem log > /dev/null
$F -s xnuloader get_staged "C:/ios26/s182b.bin" > /dev/null
strings -n 5 /mnt/c/ios26/s182b.bin > /tmp/s182b.txt
echo "=== injections ==="
grep -a 'annibale-env:' /tmp/s182b.txt | sort -u | head -20
echo "=== matched/thumbs ==="
echo "matched: $(grep -ac 'sync matched' /tmp/s182b.txt)  thumbs: $(grep -ac 'thumb [0-9]*:' /tmp/s182b.txt)"
grep -a 'sync matched' /tmp/s182b.txt | head -4
grep -a 'thumb [0-9]*:' /tmp/s182b.txt | head -6
echo "last ts: $(grep -a -oE '2025-12-10 [0-9:.]+\+0800' /tmp/s182b.txt | tail -1)"
</>
