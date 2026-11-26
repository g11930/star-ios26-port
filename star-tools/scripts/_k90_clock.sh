#!/bin/bash
K=/root/star26/k90ref/kernel/xnu/files/bsd/dev/adreno8
echo "===== K90 adreno8_clock.c 行数 ====="
wc -l "$K/adreno8_clock.c"
echo "===== 调频相关函数/符号 ====="
grep -n -i -E "^[a-z].*speed|^[a-z].*freq|vote|rpmh|request_|boost|throttle|set_speed|get_speed|workload|load" "$K/adreno8_clock.c" | head -60
