#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
C=/root/star26/star-native/iokit/Kernel/StarDisplayCompat.cpp
echo "===== GPU_SPEED_DEFAULT / core_khz / temperature decl in annibale_adreno.c ====="
grep -n -E "GPU_SPEED_DEFAULT|core_khz|annibale_gpu_temperature|annibale_gpu_speed" "$F" | head -30
echo
echo "===== StarDisplayCompat.cpp: annibale_gpu_speed / temperature ====="
grep -n -E "annibale_gpu_speed|annibale_gpu_temperature|annibale_gpu_worked" "$C" | head -20
echo
echo "===== annibale_gpu.h / declarations ====="
grep -rn -E "annibale_gpu_speed|annibale_gpu_temperature|annibale_gpu_worked" /root/star26/star-native/bsd/dev/star/*.h /root/star26/star-native/iokit/Kernel/AnnibaleGPU*.h 2>/dev/null | head -20
