#!/bin/bash
F=/root/ref2/annibale-kernel/xnu/files/bsd/dev/adreno8/adreno8_hfi.c
echo "===== K90 adreno8_speed_tick / speed_state 实现 (700-820) ====="
sed -n '700,820p' "$F"
