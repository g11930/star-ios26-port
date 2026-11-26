#!/bin/bash
K90=/root/star26/k90ref/kernel/xnu/files/bsd/dev/adreno8/adreno8_hfi.c
echo "===== K90: speed_tick / speed_state / speed 相关符号行号 ====="
grep -n -E "adreno8_speed_tick|adreno8_speed_state|adreno8_speed_vote|adreno8_speeds\[\]|struct.*adreno8_speed|GPU_SPEED_DEFAULT|permille|speed_floor|speed_change|adreno8_speed_get" "$K90"
echo
echo "===== K90: speed_tick + speed_state 全文 (定位后输出) ====="
L=$(grep -n "adreno8_speed_tick" "$K90" | head -1 | cut -d: -f1)
if [ -n "$L" ]; then sed -n "$((L-2)),$((L+180))p" "$K90"; fi
