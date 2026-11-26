#!/bin/bash
echo "===== K90 annibale_cpufreq.c 温度实现 ====="
grep -n -B3 -A45 "annibale_gpu_temperature" /root/star26/k90ref/kernel/xnu/files/bsd/dev/annibale/annibale_cpufreq.c | head -70
