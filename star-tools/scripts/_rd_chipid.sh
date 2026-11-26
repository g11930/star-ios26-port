#!/bin/bash
R=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "=== GPU_CHIP_ID / 642L / 660 ==="
grep -n "GPU_CHIP_ID\|642\|660\|Adreno 6" "$R" | head -20
echo
echo "=== gpu_kept set/clear ==="
grep -n "gpu_kept" "$R" | head -20
