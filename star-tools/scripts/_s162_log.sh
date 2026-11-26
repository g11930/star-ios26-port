#!/bin/bash
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
$F -s xnuloader oem log
$F -s xnuloader get_staged "C:/ios26/s162d-live.bin"
strings -n 5 /mnt/c/ios26/s162d-live.bin > /tmp/s162d.txt
echo "=== touch lines ==="
grep -a -i 'goodix\|annibale-touch' /tmp/s162d.txt | head -25
echo "=== count ==="
grep -a -c -i 'goodix' /tmp/s162d.txt
</>
