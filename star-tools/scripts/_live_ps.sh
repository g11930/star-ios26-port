#!/bin/bash
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
$F -s xnuloader oem sh ps 2>&1 | tail -2
sleep 4
$F -s xnuloader oem log > /dev/null
$F -s xnuloader get_staged "C:/ios26/live-ps.bin" > /dev/null
strings -n 4 /mnt/c/ios26/live-ps.bin > /tmp/ps.txt
echo "=== annsh lines ==="
grep -a 'annsh' /tmp/ps.txt | tail -40
</>
