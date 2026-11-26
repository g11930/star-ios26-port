#!/bin/bash
echo "===== K90 annibale_gpu_temperature 实现 ====="
grep -rn -A40 "^bool\s*$\|annibale_gpu_temperature" /root/star26/k90ref/kernel/xnu/files/bsd/dev/adreno8/*.c 2>/dev/null | grep -A40 "annibale_gpu_temperature(int32_t" | head -50
echo
echo "===== 全局搜 K90 温度实现文件 ====="
grep -rln "annibale_gpu_temperature" /root/star26/k90ref/kernel/xnu/files/ 2>/dev/null | head
echo
echo "===== star 侧 annibale_input.h 温度声明上下文 ====="
sed -n '80,95p' /root/star26/star-native/bsd/sys/annibale_input.h
