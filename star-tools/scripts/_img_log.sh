#!/bin/bash
strings -n 5 /mnt/c/ios26/s165d-live.bin > /tmp/g.txt
for k in ImageIO imageio CUICatalog MobileIcons iconservicesAgent iconservicesagent Assets.car heic HEIC 'decode' 'JPEG' 'CGImage' 'IOSurface' 'IconServices' 'icon cache' 'placeholder'; do
  n=$(grep -a -c "$k" /tmp/g.txt)
  [ "$n" != "0" ] && echo "$k = $n"
done
echo "=== sample CG/ImageIO lines ==="
grep -a -i -E 'imagine|CGImage|ImageIO|decode|heic|jpeg|assets\.car|cuicatalog' /tmp/g.txt | head -20
</>
