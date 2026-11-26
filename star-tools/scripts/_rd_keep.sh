#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "=== 4110-4140 (gpu_kept = true) ==="
sed -n '4110,4140p' "$F"
