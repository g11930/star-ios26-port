#!/bin/bash
sleep 200
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
$F -s xnuloader oem log > /dev/null
$F -s xnuloader get_staged "C:/ios26/s178b.bin" > /dev/null
strings -n 5 /mnt/c/ios26/s178b.bin > /tmp/s178b.txt
echo "=== matched ==="; grep -ac 'sync matched' /tmp/s178b.txt
grep -a 'sync matched' /tmp/s178b.txt | head -4
echo "=== thumbs ==="; grep -ac 'thumb [0-9]*:' /tmp/s178b.txt
grep -a 'thumb [0-9]*:' /tmp/s178b.txt | head -6
echo "=== groups ==="; grep -a 'thumb group' /tmp/s178b.txt | head -4
echo "=== last ts ==="; grep -a -oE '2025-12-10 [0-9:.]+\+0800' /tmp/s178b.txt | tail -1
$F -s xnuloader oem screenshot > /dev/null
$F -s xnuloader get_staged "C:/ios26/s178b-frame.raw" > /dev/null
python3 /mnt/d/桌面/star26-deps/scripts/fb2png.py /mnt/c/ios26/s178b-frame.raw /mnt/c/ios26/s178b-frame.png
ls -l /mnt/c/ios26/s178b-frame.png
</>
