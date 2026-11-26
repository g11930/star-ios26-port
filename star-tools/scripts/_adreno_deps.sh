#!/bin/bash
F=/root/g11930-ref/xnu/files/bsd/dev/redwood_adreno.c
echo "=== includes ==="
grep -n '^#include' $F
echo
echo "=== what else it references that lives in another redwood file ==="
for sym in pmic rpmh gdsc clock smmu iommu regulator geni tlmm; do
  printf "%-10s %s\n" "$sym" "$(grep -c -i "$sym" $F)"
done
echo
echo "=== exported helpers it calls (annibale_*/redwood_* not defined in this file) ==="
grep -o '\bredwood_[a-z_0-9]*' $F | sort -u | head -40
echo
echo "=== does the file define its own platform hooks? ==="
grep -n '^[a-z].*(' $F | grep -v ';' | head -30
echo
echo "=== our tree: does annibale_input.h declare the gpu hooks ==="
grep -n 'annibale_gpu' /root/star26/star-native/bsd/sys/annibale_input.h 2>/dev/null | head -20
