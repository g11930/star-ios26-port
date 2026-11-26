#!/bin/bash
find /root/star26 /root/g11930-ref /root/k90-src -name 'annibalemetal.m' 2>/dev/null | head -5
echo "=== any metal shim dir in star26 ==="
find /root/star26 -maxdepth 4 -type d -name 'userland-driver' 2>/dev/null | head -5
echo "=== dylib in staging ==="
ls -l /root/star26/s111/work/rootbuild/root/lib/libannibalemetal.dylib 2>/dev/null
</>
