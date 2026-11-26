#!/bin/bash
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
$F -s xnuloader oem log > /dev/null
$F -s xnuloader get_staged "C:/ios26/s164d-live.bin" > /dev/null
strings -n 5 /mnt/c/ios26/s164d-live.bin > /tmp/s164.txt
echo "goodix count: $(grep -a -c 'goodix' /tmp/s164.txt)"
grep -a 'goodix' /tmp/s164.txt | head -16
</>
