#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "===== [1] edit1 status: star_gpu_speeds / floor ====="
grep -n "star_gpu_speeds\|GPU_SPEED_DEFAULT\|star_speed_floor\|star_speed_want" "$F" | head -25
echo
echo "===== [2] submit / times / ticks symbols ====="
grep -n "annibale_gpu_submit\|gpu_times\|gpu_ticks\|gpu_timed_count\|gpu_fence\|gpu_kept\|annibale_gpu_worked" "$F" | head -40
echo
echo "===== [3] submit function body ====="
LINE=$(grep -n "^annibale_gpu_submit" "$F" | head -1 | cut -d: -f1)
echo "submit at line $LINE"
sed -n "$((LINE-18)),$((LINE+75))p" "$F"
