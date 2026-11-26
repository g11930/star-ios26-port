#!/bin/bash
L=/root/star26/s111/work/rootbuild/root/lib/libannibaleair.dylib
echo "=== thumbnail hook exported? ==="
strings -a $L | grep -i 'texture_thumbnail' | head -5
echo "=== names in mesa glue source ==="
grep -rn 'texture_thumbnail' /root/star26/hackios-xnu-kernel/tools/userland-driver/annibalemetal_mesa.inc /root/star26/hackios-xnu-kernel/tools/userland-driver/annibalemetal.m | head -6
</>
