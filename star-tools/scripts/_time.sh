#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "===== 时间相关: mach_absolute_time / sleep_us / clock_get / rdtsc ====="
grep -n "mach_absolute_time\|sleep_us\|clock_get\|nanoseconds\|absolutetime" "$F" | head -15
echo
echo "===== gpu_times 函数定义 ====="
grep -n "gpu_times(void)\|^gpu_times" "$F" | head
echo "===== mach_absolute_time 在 star 树里的声明 ====="
grep -rn "mach_absolute_time" /root/star26/star-native/bsd/dev/star/*.c 2>/dev/null | head -8
