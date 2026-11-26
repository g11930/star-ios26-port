#!/bin/bash
# 找 K90 的 speed_tick 定义位置
K=/root/star26/k90ref
F=$(find "$K" -name "adreno8_hfi.c" 2>/dev/null | head -1)
echo "HFI file: $F"
echo "===== speed_tick / speed_state 符号 ====="
grep -n "adreno8_speed_tick\|adreno8_speed_state\|speed_tick\|speed_state" "$F" | head -20
