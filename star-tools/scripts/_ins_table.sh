#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "===== 2300-2345: core_khz / speeds 表区 ====="
sed -n '2300,2345p' "$F"
echo "===== 2410-2470: step_core_power 投票区 ====="
sed -n '2410,2470p' "$F"
echo "===== submit 函数头 ====="
grep -n "annibale_gpu_submit" "$F" | head -5
