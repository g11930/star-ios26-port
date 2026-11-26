#!/bin/bash
echo "===== [A] 全树找 annibale_gpu_speed ====="
grep -rn "annibale_gpu_speed" /root/star26/star-native/ 2>/dev/null | grep -v ".o:" | head -20
echo
echo "===== [B] 声明所在头文件 ====="
grep -rn "annibale_gpu_speed\|annibale_gpu_temperature\|annibale_gpu_worked" /root/star26/star-native/bsd/dev/star/annibale_input.h
echo
echo "===== [C] StarDisplayCompat.cpp 里的 weak 桩 ====="
grep -rn -B3 -A8 "annibale_gpu_speed\|annibale_gpu_temperature" /root/star26/star-native/bsd/dev/star/StarDisplayCompat.cpp 2>/dev/null | head -40
