#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "===== key symbols ====="
grep -n -E "step_core_power|star_gpu_speeds|gpu_ticks|gpu_timed_count|hfi_send|annibale_gpu_submit|annibale_gpu_temperature|annibale_gpu_speed|HFI_GX_BW_PERF_VOTE" "$F" | head -50
echo
echo "===== file line count ====="
wc -l "$F"
