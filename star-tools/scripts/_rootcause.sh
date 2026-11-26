#!/bin/bash
echo "===== K90 adreno8_context_drained 实现 ====="
grep -rn "adreno8_context_drained" /root/star26/k90ref/kernel/xnu/files/bsd/dev/adreno8/*.c 2>/dev/null | head
K=$(grep -rl "^adreno8_context_drained" /root/star26/k90ref/kernel/xnu/files/bsd/dev/adreno8/*.c 2>/dev/null | head -1)
echo "file: $K"
LINE=$(grep -n "^adreno8_context_drained" "$K" 2>/dev/null | head -1 | cut -d: -f1)
if [ -n "$LINE" ]; then sed -n "$((LINE-2)),$((LINE+45))p" "$K"; fi
echo
echo "===== star: tick 处的 gpu_fence / annibale_gpu_done 可用性 ====="
F=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
grep -n "static uint32_t gpu_fence\|static bool gpu_kept\|annibale_gpu_done\|star_gpu_speed_tick" "$F" | head -12
