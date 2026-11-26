#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "===== step_core_power speeds 表与投票区 ====="
grep -n "step_core_power\|star_gpu_speeds\|static.*gpu_speeds\|core_khz\|perf_table\|hfi_send\|HFI_GX_BW_PERF_VOTE\|HFI_NO_INDEX\|gpu_ticks\|gpu_timed_count\|annibale_gpu_submit\|annibale_gpu_temperature\|annibale_gpu_speed" "$F" | head -60
