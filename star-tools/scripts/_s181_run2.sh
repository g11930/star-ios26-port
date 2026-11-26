#!/bin/bash
A=/mnt/d/桌面/adb-fastboot/adb.exe
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
$A reboot bootloader
sleep 12
$F devices
$F boot "C:/ios26/s181-boot.img"
sleep 200
$F -s xnuloader oem log > /dev/null
$F -s xnuloader get_staged "C:/ios26/s181a.bin" > /dev/null
strings -n 5 /mnt/c/ios26/s181a.bin > /tmp/s181a.txt
echo "=== injection notes ==="
grep -a 'annibale-env:' /tmp/s181a.txt | sort -u | head -20
echo "=== matched/thumbs ==="
echo "matched: $(grep -ac 'sync matched' /tmp/s181a.txt)  thumbs: $(grep -ac 'thumb [0-9]*:' /tmp/s181a.txt)"
echo "last ts: $(grep -a -oE '2025-12-10 [0-9:.]+\+0800' /tmp/s181a.txt | tail -1)"
</>
