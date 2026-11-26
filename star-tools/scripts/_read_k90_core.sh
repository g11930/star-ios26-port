#!/bin/bash
echo "===== K90: 找 speed_tick 所在文件 ====="
find /root/star26/k90ref -name "*.c" | xargs grep -ln "adreno8_speed_tick\|adreno8_speed_state" 2>/dev/null
echo "===== K90: annibale_gpu_dispatch.c 150-210 ====="
sed -n '150,210p' /root/star26/k90ref/kernel/xnu/files/bsd/dev/annibale/annibale_gpu_dispatch.c
echo "===== K90: annibale_gpu_temperature 实现 (cpufreq 249-330) ====="
sed -n '249,330p' /root/star26/k90ref/kernel/xnu/files/bsd/dev/annibale/annibale_cpufreq.c
