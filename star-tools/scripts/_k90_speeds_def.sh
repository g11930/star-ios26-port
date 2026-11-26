#!/bin/bash
K=/root/star26/k90ref/kernel/xnu/files/bsd/dev/adreno8
echo "===== adreno8_speeds / gx_hz / speed_asked decl ====="
grep -rn -E "adreno8_speeds|adreno8_gx_hz|adreno8_speed_asked|adreno8_gx_count" "$K"/*.c "$K"/*.h 2>/dev/null | grep -v "adreno8_hfi.c" | head -30
echo
echo "===== speeds table def ====="
grep -rn -B3 -A15 "adreno8_speeds\s*=\|adreno8_speeds\[\]" "$K"/ 2>/dev/null | head -40
