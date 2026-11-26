#!/bin/bash
for d in /root/star26/s111/work/rootbuild/root/annibale/lib /root/star26/hackios-xnu-kernel/tools/userland-driver; do
  echo "=== $d"; ls $d 2>/dev/null | head -6
done
echo "=== search dylibs anywhere ==="
find /root/star26 -maxdepth 6 -name 'libannibale*.dylib' 2>/dev/null | head -8