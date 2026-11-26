#!/bin/bash
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
$F -s xnuloader oem log > /dev/null
$F -s xnuloader get_staged "C:/ios26/s165d-live.bin" > /dev/null
strings -n 5 /mnt/c/ios26/s165d-live.bin > /tmp/s165.txt
echo "goodix count: $(grep -a -c 'goodix' /tmp/s165.txt)"
grep -a 'goodix' /tmp/s165.txt | head -30
</>
