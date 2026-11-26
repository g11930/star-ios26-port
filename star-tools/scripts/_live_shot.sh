#!/bin/bash
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
$F -s xnuloader oem screenshot > /dev/null 2>&1
$F -s xnuloader get_staged "C:/ios26/live-now.raw" > /dev/null
python3 /mnt/d/桌面/star26-deps/scripts/fb2png.py /mnt/c/ios26/live-now.raw /mnt/c/ios26/live-now.png
python3 - <<PY
d=open('/mnt/c/ios26/live-now.raw','rb').read()
nz=sum(1 for b in d if b)
print('nonzero', nz, 'of', len(d))
PY
tail -c 2000 /tmp/ps.txt | head -30
</</>
