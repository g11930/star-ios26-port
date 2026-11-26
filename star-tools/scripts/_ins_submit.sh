#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "===== 3690-3760: submit 函数与忙计数 ====="
sed -n '3690,3760p' "$F"
echo "===== weak 声明位置 ====="
grep -n "annibale_gpu_speed\|annibale_gpu_temperature" "$F"
echo "===== StarDisplayCompat weak 桩 ====="
grep -rn "annibale_gpu_speed" /root/star26/star-native/bsd/dev/star/StarDisplayCompat.cpp /root/star26/star-native/bsd/dev/star/*.cpp /root/star26/star-native/bsd/dev/star/*.h 2>/dev/null | head -10
