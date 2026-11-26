#!/bin/bash
sleep 180
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
$F -s xnuloader oem log > /dev/null
$F -s xnuloader get_staged "C:/ios26/s179b.bin" > /dev/null
strings -n 5 /mnt/c/ios26/s179b.bin > /tmp/s179b.txt
echo "env lines:"; grep -a 'kern.annibale.env:' /tmp/s179b.txt | sed 's/.*kern.annibale.env:/env:/' | sort -u | head -14
echo "matched: $(grep -ac 'sync matched' /tmp/s179b.txt)  thumbs: $(grep -ac 'thumb [0-9]*:' /tmp/s179b.txt)"
grep -a 'sync matched' /tmp/s179b.txt | head -5
grep -a 'thumb [0-9]*:' /tmp/s179b.txt | head -6
echo "last ts: $(grep -a -oE '2025-12-10 [0-9:.]+\+0800' /tmp/s179b.txt | tail -1)"
$F -s xnuloader oem screenshot > /dev/null
$F -s xnuloader get_staged "C:/ios26/s179b-frame.raw" > /dev/null
python3 /mnt/d/桌面/star26-deps/scripts/fb2png.py /mnt/c/ios26/s179b-frame.raw /mnt/c/ios26/s179b-frame.png
ls -l /mnt/c/ios26/s179b-frame.png
</>
