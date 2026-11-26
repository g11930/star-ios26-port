#!/bin/bash
echo "=== env sysctl lines anywhere ==="
grep -a -E 'kern.annibale|MESA_SHADER' /tmp/s174d.txt | head -8
echo "=== metal/compute activity ==="
grep -a -c 'compute pipeline' /tmp/s174d.txt
grep -a -c 'ir3 compile' /tmp/s174d.txt
grep -a 'annibalemetal\[SpringBoard' /tmp/s174d.txt | tail -4
echo "=== SpringBoard alive / desktop ==="
grep -a -E 'SpringBoard\[|Wallpaper|SBIcon' /tmp/s174d.txt | tail -6
echo "=== frame ==="
python3 /mnt/d/桌面/star26-deps/scripts/fb2png.py /mnt/c/ios26/s174c-frame.raw /mnt/c/ios26/s174c-frame.png
ls -l /mnt/c/ios26/s174c-frame.png
</>
