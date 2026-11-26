#!/bin/bash
echo "=== SOC base constant in the ported driver ==="
grep -n 'SOC_BASE' /root/star26/star-native/bsd/dev/star/annibale_adreno.c | head -5
echo "star's soc base from pexpert ==="
grep -rn 'soc_base\|SOC_BASE' /root/star26/star-native/pexpert/pexpert/arm64/*.h 2>/dev/null | head -5
echo
echo "=== where is annibale_input_init defined ==="
grep -rn 'annibale_input_init' /root/star26/star-native --include=*.c --include=*.h | head -5
echo
echo "=== reference input.c around the call ==="
sed -n '215,232p' /root/g11930-ref/xnu/files/bsd/dev/redwood_input.c
