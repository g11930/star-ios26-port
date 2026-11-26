#!/bin/bash
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
$F -s xnuloader oem log > /dev/null 2>&1
$F -s xnuloader get_staged "C:/ios26/s175h.bin" > /dev/null 2>&1
strings -n 5 /mnt/c/ios26/s175h.bin > /tmp/s175h.txt
echo "lines $(wc -l < /tmp/s175h.txt) last $(grep -a -oE '2025-12-10 [0-9:.]+\+0800' /tmp/s175h.txt | tail -1)"
echo "pipelines $(grep -ac 'render pipelines' /tmp/s175h.txt) ir3wait $(grep -ac 'ir3 wait' /tmp/s175h.txt)"
grep -a 'render pipelines' /tmp/s175h.txt | tail -3
echo "--- last 6 timestamped"
grep -a '2025-12-10' /tmp/s175h.txt | tail -6 | cut -c1-140