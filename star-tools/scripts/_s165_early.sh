#!/bin/bash
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
$F -s xnuloader oem stop > /dev/null
sleep 3
$F -s xnuloader reboot bootloader > /dev/null 2>&1
sleep 6
$F -s xnuloader boot C:/ios26/s165-boot.img
sleep 30
$F -s xnuloader oem log > /dev/null
$F -s xnuloader get_staged "C:/ios26/s165e-live.bin" > /dev/null
strings -n 5 /mnt/c/ios26/s165e-live.bin > /tmp/s165e.txt
echo "goodix=$(grep -a -c goodix /tmp/s165e.txt) touch=$(grep -a -c 'annibale-touch' /tmp/s165e.txt)"
grep -a -i 'goodix\|annibale-touch\|device ready' /tmp/s165e.txt | head -12
</>
