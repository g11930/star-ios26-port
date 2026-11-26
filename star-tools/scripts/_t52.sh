#!/bin/bash
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
IMG=${IMG:-C:/ios26/s208-boot.img}
$F boot "$IMG" 2>&1 | tail -2
sleep 200
$F -s xnuloader oem log > /dev/null 2>&1
$F -s xnuloader get_staged "C:/ios26/s208a.bin" > /dev/null 2>&1
strings -n 5 /mnt/c/ios26/s208a.bin > /tmp/s208a.txt
echo "lines $(wc -l < /tmp/s208a.txt) last $(grep -a -oE '2025-12-[0-9]+ [0-9:.]+\+0800' /tmp/s208a.txt | tail -1)"
echo "=== frame stats ==="
grep -a 'frames in' /tmp/s208a.txt | tail -8