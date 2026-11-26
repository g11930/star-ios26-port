#!/bin/bash
K=/root/star26/k90ref/kernel/xnu/files/bsd/dev/adreno8/adreno8_hfi.c
echo "===== 700-860: 常量与 speed_tick/state 完整 ====="
sed -n '700,860p' "$K"
