#!/bin/bash
# 读 K90 参考：adreno8_hfi.c speed_tick/speed_state + annibale_gpu_dispatch.c + speeds 表
K90=/root/star26/k90ref/kernel/xnu/files/bsd/dev
echo "===== K90 adreno8_hfi.c speed_tick/speed_state ====="
grep -n -E "adreno8_speed_tick|adreno8_speed_state|adreno8_speed_vote|adreno8_speed_get|HFI_GX_BW_PERF_VOTE|permille|speed_floor|speed_change" "$K90/adreno8_hfi.c" | head -40
echo "===== K90 annibale_gpu_dispatch.c ====="
grep -n -E "annibale_gpu_speed|annibale_gpu_temperature|annibale_gpu_tick|speed_changes|speed_mhz" "$K90/annibale/annibale_gpu_dispatch.c" 2>/dev/null | head -30
echo "===== K90 speeds 表（含 bus） ====="
grep -rn -E "adreno8_speeds\[\]|struct.*speed|bus_vote|HFI_NO_INDEX" "$K90/adreno8_hfi.c" | head -20
echo "===== K90 温度实现 ====="
grep -rn -E "annibale_gpu_temperature|tsens|thermistor" "$K90/" 2>/dev/null | head -15
