#!/bin/bash
K90=/root/star26/k90ref/kernel/xnu/files/bsd/dev/adreno8/adreno8_hfi.c
echo "===== K90: speed_tick + speed_state 完整 (720-840) ====="
sed -n '720,840p' "$K90"
echo
echo "===== K90: speeds 表定义 (找 adreno8_gx_hz / adreno8_speeds) ====="
grep -n -E "adreno8_gx_hz|adreno8_speeds\[\]|SPEED_TICK_NS|SPEED_UP_PERMILLE|SPEED_DOWN_PERMILLE|SPEED_TARGET_PERMILLE|SPEED_COOL|SPEED_HOT" "$K90" | head -20
echo
echo "===== K90: speed_vote 消息发送（改档） ====="
grep -n -B3 -A12 "adreno8_speed_vote\|HFI_GX_BW_PERF_VOTE" "$K90" | head -40
