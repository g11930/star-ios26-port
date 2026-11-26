#!/bin/bash
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
$F -s xnuloader oem stop
sleep 4
$F -s xnuloader boot C:/ios26/s161-boot.img
sleep 6
$F -s xnuloader oem log
$F -s xnuloader get_staged "C:/ios26/s161f-live.bin"
strings -n 5 /mnt/c/ios26/s161f-live.bin > /tmp/s161f.txt
grep -a -i 'goodix\|annibale-touch\|FTS\|touch screen' /tmp/s161f.txt | head -20
</>
