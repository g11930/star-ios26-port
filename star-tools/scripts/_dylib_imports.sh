#!/bin/bash
L=/root/star26/s111/work/rootbuild/root/lib
ls -la $L | grep -i 'sbmetal\|annibaleair' | head
D=$L/libannibale-sbmetal-experiment.dylib
echo "=== undefined imports of the sbmetal dylib ==="
nm -u $D 2>/dev/null | grep -i 'IOService\|IOMaster\|mach_msg' | head -20
echo "=== does it define them itself? ==="
nm -gU $D 2>/dev/null | grep -i 'IOService' | head -10
echo
echo "=== and the metal driver dylib (mesa based) ==="
for F in $L/*.dylib; do
  if nm -u "$F" 2>/dev/null | grep -q 'IOServiceGetMatchingService'; then
    echo "--- $F"
    nm -u "$F" 2>/dev/null | grep -i 'IOServiceGetMatching' | head -3
  fi
done
</bash>
