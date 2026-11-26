#!/bin/bash
echo "=== who calls adreno_init in the reference tree ==="
grep -rn 'adreno_init' /root/g11930-ref/xnu --include=*.c --include=*.h 2>/dev/null | grep -v 'redwood_adreno.c:' | head -10
echo
echo "=== in our tree ==="
grep -rn 'annibale_adreno_init' /root/star26/star-native --include=*.c --include=*.cpp --include=*.h 2>/dev/null | head -10
echo
echo "=== star: how platform drivers are started (bsd_init hooks) ==="
grep -n 'star_\|annibale_' /root/star26/star-native/bsd/kern/bsd_init.c | head -20
echo
echo "=== staging: GPU firmware present? ==="
ls /root/star26/s111/work/rootbuild/root/fw 2>/dev/null | head -20
echo "--- plain fw in apfs? ---"
ls -la /root/star26/s111/work/rootbuild/root | head -12
