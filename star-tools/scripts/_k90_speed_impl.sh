#!/bin/bash
echo "===== star StarDisplayCompat.cpp: annibale_gpu_speed weak 声明 ====="
sed -n '100,135p' /root/star26/star-native/iokit/Kernel/StarDisplayCompat.cpp
echo
echo "===== star AnnibaleGPUSubmit.inc: submit 调用点 ====="
sed -n '200,245p' /root/star26/star-native/iokit/Kernel/AnnibaleGPUSubmit.inc
echo
echo "===== K90 adreno8_speed_tick / adreno8_speed_state 定义位置 ====="
grep -rn "adreno8_speed_tick\|adreno8_speed_state" /root/ref2/annibale-kernel/xnu/files/bsd/dev/adreno8/ 2>/dev/null | head -20
