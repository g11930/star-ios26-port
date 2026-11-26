#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "===== star 侧 gpu_kept 声明 ====="
grep -n "gpu_kept" "$F" | head
echo
echo "===== 温度声明在哪个头文件 ====="
grep -rn "annibale_gpu_temperature\|annibale_gpu_speed\|annibale_gpu_worked" /root/star26/star-native/bsd/dev/star/*.h /root/star26/star-native/iokit/Kernel/*.h 2>/dev/null | head -20
echo
echo "===== step 变量 ====="
grep -n "^static uint32_t step\|^uint32_t step" "$F" | head
