#!/bin/bash
A=/mnt/d/桌面/adb-fastboot/adb.exe
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
$A reboot bootloader
for i in $(seq 1 20); do sleep 2; $F devices | grep -q fastboot && break; done
$F devices
$F boot "C:/ios26/s182-boot.img"
sleep 250
$F -s xnuloader oem log > /dev/null
$F -s xnuloader get_staged "C:/ios26/s182c.bin" > /dev/null
strings -n 5 /mnt/c/ios26/s182c.bin > /tmp/s182c.txt
echo "=== injections ==="
grep -a 'annibale-env:' /tmp/s182c.txt | sort -u | head -20
echo "=== matched/thumbs ==="
echo "matched: $(grep -ac 'sync matched' /tmp/s182c.txt)  thumbs: $(grep -ac 'thumb [0-9]*:' /tmp/s182c.txt)"
grep -a 'sync matched' /tmp/s182c.txt | head -4
echo "last ts: $(grep -a -oE '2025-12-10 [0-9:.]+\+0800' /tmp/s182c.txt | tail -1)"
</>
