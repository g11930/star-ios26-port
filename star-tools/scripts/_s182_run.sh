#!/bin/bash
A=/mnt/d/桌面/adb-fastboot/adb.exe
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
$A reboot bootloader 2>/dev/null
sleep 12
$F boot "C:/ios26/s182-boot.img"
sleep 240
$F -s xnuloader oem log > /dev/null
$F -s xnuloader get_staged "C:/ios26/s182a.bin" > /dev/null
strings -n 5 /mnt/c/ios26/s182a.bin > /tmp/s182a.txt
echo "=== injections ==="
grep -a 'annibale-env:' /tmp/s182a.txt | sort -u | head -20
echo "=== matched/thumbs ==="
echo "matched: $(grep -ac 'sync matched' /tmp/s182a.txt)  thumbs: $(grep -ac 'thumb [0-9]*:' /tmp/s182a.txt)"
grep -a 'sync matched' /tmp/s182a.txt | head -4
grep -a 'thumb [0-9]*:' /tmp/s182a.txt | head -6
echo "last ts: $(grep -a -oE '2025-12-10 [0-9:.]+\+0800' /tmp/s182a.txt | tail -1)"
</>
