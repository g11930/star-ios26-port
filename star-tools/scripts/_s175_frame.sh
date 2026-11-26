#!/bin/bash
python3 /mnt/d/桌面/star26-deps/scripts/fb2png.py /mnt/c/ios26/s175c-frame.raw /mnt/c/ios26/s175c-frame.png
ls -l /mnt/c/ios26/s175c-frame.png
echo "=== boot timeline: last 8 timestamps in log ==="
grep -a -oE '2025-12-10 [0-9:.]+\+0800' /tmp/s175d.txt | tail -4
echo "=== desktop reached? ==="
grep -a -cE 'com.apple.SpringBoard.SceneWorkspace|Icon'  /tmp/s175d.txt
</>
