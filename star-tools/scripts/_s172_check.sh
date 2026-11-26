#!/bin/bash
python3 /mnt/d/桌面/star26-deps/scripts/fb2png.py /mnt/c/ios26/s172c-frame.raw /mnt/c/ios26/s172c-frame.png > /dev/null
ls -l /mnt/c/ios26/s172c-frame.png
echo "=== triangle/metal_props ==="
grep -a -E 'triangle_app|metal_props' /tmp/s172.txt | head -8
echo "=== boot outcome ==="
grep -a -E 'SpringBoard|backboardd' /tmp/s172.txt | tail -4
</>
