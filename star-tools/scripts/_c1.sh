#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "===== A: step_core_power speeds 表 (2300-2400) ====="
sed -n '2300,2400p' "$F"
echo "===== B: 符号定位 ====="
grep -n -E "step_core_power|hfi_send|annibale_gpu_submit|annibale_gpu_temperature|gpu_ticks|gpu_timed_count|annibale_gpu_speed|tsens" "$F" | head -40
