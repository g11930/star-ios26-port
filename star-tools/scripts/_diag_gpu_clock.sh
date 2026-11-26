#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "=== [1] star: speed levels / perf table ==="
grep -n -E "gpu_levels|gpu_level|perf\.|freq|MHz|mhz|dcvs|DCVS|bandwidth|bw_|vote|rpmh" "$F" | head -70
echo
echo "=== [2] star: clock source (step 5 / clock driver) ==="
ls /root/star26/star-native/bsd/dev/star/ | grep -i -E "clock|rpmh|cc_"
echo
echo "=== [3] K90 docs on gpu clock / 120hz ==="
sed -n '1,80p' /root/star26/k90ref/docs/docs/analysis/2026-11-02-120hz-after-gpu-clock.md
