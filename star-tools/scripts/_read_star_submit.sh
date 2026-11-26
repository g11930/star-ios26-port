#!/bin/bash
K=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "===== star: 找 weak annibale_gpu_speed 声明 ====="
grep -rn "annibale_gpu_speed" /root/star26/star-native/bsd/dev/star/ /root/star26/star-native/iokit/ 2>/dev/null | grep -v "\.inc"
echo
echo "===== star: annibale_gpu_submit 函数 (3728-3790) ====="
sed -n '3728,3790p' "$K"
echo
echo "===== star: gpu_ticks 累加上下文 (3690-3725) ====="
sed -n '3690,3725p' "$K"
echo
echo "===== star: GPU_SPEED_DEFAULT / HFI_NO_INDEX 定义 ====="
grep -n -E "GPU_SPEED_DEFAULT|HFI_NO_INDEX|core_khz" "$K" | head -15
echo
echo "===== star: annibale_adreno_minute 调用点（看在哪注册） ====="
grep -n "annibale_adreno_minute\|annibale_minute\|_minute" "$K" | head -10
