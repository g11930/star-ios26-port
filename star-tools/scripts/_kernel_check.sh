#!/bin/bash
K=/root/star26/s111/parts/kernel
for s in adreno SMMU_CB_TLBIASID zap CP_RB_BASE 'GPU kept on' 'annibale_gpu_' RBBM; do
  printf "%-24s %s\n" "$s" "$(strings -n 6 "$K" | grep -ci -- "$s")"
done
echo
echo "=== driver's own log lines present? ==="
strings -n 10 "$K" | grep -i 'annibale\|adreno' | grep -i 'step\|gpu\|mhz' | head -8
