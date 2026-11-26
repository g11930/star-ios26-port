#!/bin/bash
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
$F -s xnuloader oem log > /dev/null
$F -s xnuloader get_staged "C:/ios26/s166d-live.bin" > /dev/null
strings -n 5 /mnt/c/ios26/s166d-live.bin > /tmp/s166.txt
echo "goodix=$(grep -a -c 'goodix' /tmp/s166.txt)"
grep -a 'goodix' /tmp/s166.txt | head -40
</>
