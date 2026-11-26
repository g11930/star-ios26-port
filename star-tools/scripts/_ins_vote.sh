#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "===== 2345-2410: speeds 表发送与投票 ====="
sed -n '2345,2410p' "$F"
echo "===== submit 函数定义位置 ====="
grep -n "annibale_gpu_submit\|gpu_ticks\|gpu_timed_count" "$F" | head -20
