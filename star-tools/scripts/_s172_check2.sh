#!/bin/bash
echo "=== triangle_app execution ==="
grep -a -E 'triangle_app|P28EXIT: pid .* triangle' /tmp/s172.txt | head -6
echo "=== desktop markers ==="
grep -a -E 'Wallpaper|SBIconController|icon layout|PosterBoard' /tmp/s172.txt | tail -4
echo "=== ir3 compile waits (lag evidence) ==="
grep -a 'ir3 wait' /tmp/s172.txt | tail -8
</>
