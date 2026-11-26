#!/bin/bash
K=/root/star26/k90ref/kernel/xnu/files/bsd/dev/adreno8/adreno8_hfi.c
echo "===== speeds table + constants ====="
grep -n -E "adreno8_gx_hz|adreno8_speeds\b|struct.*speed|SPEED_TICK_NS|SPEED_UP_PERMILLE|SPEED_DOWN_PERMILLE|SPEED_TARGET_PERMILLE|SPEED_DOWN_NS|SPEED_HOT_TENTHS|SPEED_COOL|SPEED_CUT|SPEED_RISE|SPEED_DRAIN" "$K" | head -40
echo
echo "===== adreno8_speeds struct def ====="
grep -n -B2 -A8 "adreno8_speeds\[" "$K" | head -40
