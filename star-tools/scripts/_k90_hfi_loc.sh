#!/bin/bash
K=/root/star26/k90ref/kernel/xnu/files/bsd/dev/adreno8/adreno8_hfi.c
echo "===== speed_tick / speed_state / speeds table / temp ====="
grep -n -E "adreno8_speed_tick|adreno8_speed_state|adreno8_speeds|speed_changes|gpu_busy|permille|temp|temperature|HFI_GX_BW_PERF_VOTE|speed_floor|speed_index|busy_time" "$K" | head -60
