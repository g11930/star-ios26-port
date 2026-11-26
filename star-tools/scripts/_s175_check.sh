#!/bin/bash
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
python3 /mnt/d/桌面/star26-deps/scripts/fb2png.py /mnt/c/ios26/s175c-frame.raw /mnt/c/ios26/s175c-frame.png
ls -l /mnt/c/ios26/s175c-frame.png
$F -s xnuloader oem log > /dev/null 2>&1
$F -s xnuloader get_staged "C:/ios26/s175g.bin" > /dev/null 2>&1
strings -n 5 /mnt/c/ios26/s175g.bin > /tmp/s175g.txt
echo "lines $(wc -l < /tmp/s175g.txt) last $(grep -a -oE '2025-12-10 [0-9:.]+\+0800' /tmp/s175g.txt | tail -1)"
echo "pipelines: $(grep -a 'render pipelines' /tmp/s175g.txt | wc -l)  ir3wait: $(grep -ac 'ir3 wait' /tmp/s175g.txt)"