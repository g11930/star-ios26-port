#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "===== [A] tsens 读取实现 (3930-3990) ====="
sed -n '3930,3990p' "$F"
echo
echo "===== [B] gpu_ticks / gpu_timed_count 定义与用法 ====="
grep -n "gpu_ticks\|gpu_timed_count\|gpu_timed" "$F" | head -30
echo
echo "===== [C] annibale_gpu_submit 函数体 ====="
grep -n "annibale_gpu_submit" "$F"
