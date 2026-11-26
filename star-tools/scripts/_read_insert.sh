#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "===== need() 195..215 ====="
sed -n '195,215p' "$F"
echo
echo "===== gpu_times 完整 (找起点) ====="
grep -n "^gpu_times\|^static.*gpu_times\|gpu_times(void)" "$F"
sed -n '3660,3682p' "$F"
echo
echo "===== 2305..2315 core_khz 定义区 ====="
sed -n '2305,2315p' "$F"
