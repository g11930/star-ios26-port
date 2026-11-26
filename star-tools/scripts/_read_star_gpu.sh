#!/bin/bash
# 读 star 侧：step_core_power 的 speeds 表 + gpu_ticks/gpu_timed_count + hfi_send + submit
K=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "===== step_core_power 与 speeds 表 ====="
grep -n "step_core_power" "$K"
echo "===== speeds 表 / gpu_ticks / gpu_timed_count 定义 ====="
grep -n -E "static.*speeds|gpu_ticks|gpu_timed_count|perf_table|speed_table|HFI_GX_BW_PERF_VOTE|hfi_send|star_gpu_speed|annibale_gpu_speed|annibale_gpu_submit" "$K"
echo "===== 温度 ====="
grep -n -E "annibale_gpu_temperature|tsens|temperature" "$K" | head -20
echo "===== StarDisplayCompat.cpp weak 桩 ====="
grep -n -B2 -A6 "annibale_gpu_speed" /root/star26/star-native/bsd/dev/star/StarDisplayCompat.cpp
echo "===== AnnibaleGPUSubmit.inc 报表调用 ====="
grep -n -B3 -A6 "annibale_gpu_speed" /root/star26/star-native/bsd/dev/star/AnnibaleGPUSubmit.inc 2>/dev/null || find /root/star26/star-native -name "AnnibaleGPUSubmit.inc" -exec grep -n -B3 -A6 "annibale_gpu_speed" {} \;
