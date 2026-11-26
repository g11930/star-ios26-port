#!/bin/bash
echo "===== K90 启动时 GX_BW_PERF_VOTE 初始投票格式 ====="
grep -rn -E "GX_BW_PERF_VOTE|adreno8_hfi_send\(30|adreno8_speed_asked|HFI_GX" /root/ref2/annibale-kernel/xnu/files/bsd/dev/adreno8/*.c 2>/dev/null | head -15
echo
echo "===== K90 adreno8_speed_asked 初始值与含义 ====="
grep -rn "adreno8_speed_asked" /root/ref2/annibale-kernel/xnu/files/bsd/dev/adreno8/*.c 2>/dev/null | head -10
echo
echo "===== star 侧 annibale_gpu_worked / gpu_ticks 忙计数 ====="
sed -n '3250,3330p' /root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo
echo "===== star annibale_gpu_temperature 实现（是否要 cpufreq=N）====="
grep -rn "annibale_gpu_temperature" /root/star26/star-native/bsd/dev/star/*.c 2>/dev/null | head
