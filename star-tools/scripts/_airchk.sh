#!/bin/bash
L=/root/star26/s111/work/rootbuild/root/lib
A=$L/libannibaleair.dylib
S=$L/libannibale-sbmetal-experiment.dylib
echo "=== nm sanity ==="
nm -u $S 2>&1 | head -5
echo "=== air: IOKit imports ==="
nm -u $A 2>/dev/null | grep -i 'IOService\|IOMasterPort\|IOConnect\|IORegistry' | head -12
echo "=== air: driver strings ==="
strings -n 8 $A | grep -i 'no msm device\|AnnibaleGPU\|device_open\|annibale-drm' | head -6
echo "=== sbmetal: strings ==="
strings -n 8 $S | grep -i 'annibale\|metal\|gpu' | head -8
</bash>
