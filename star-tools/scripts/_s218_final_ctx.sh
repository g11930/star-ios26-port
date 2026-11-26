#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
H=/root/star26/star-native/bsd/sys/annibale_input.h
echo "===== [1] HFI_GX_BW_PERF_VOTE / HFI 常量定义 ====="
grep -n "HFI_GX_BW_PERF_VOTE\|HFI_PERF_TABLE\|HFI_BW_TABLE\|HFI_NO_INDEX\|#define HFI_" "$F" | head -25
echo
echo "===== [2] annibale_gpu_temperature / speed 声明 ====="
grep -n "annibale_gpu_temperature\|annibale_gpu_speed" "$H"
echo
echo "===== [3] annibale_adreno_minute 温度读数完整 ====="
sed -n '3960,3995p' "$F"
echo
echo "===== [4] annibale_gpu_done 实现 ====="
LINE=$(grep -n "^annibale_gpu_done" "$F" | head -1 | cut -d: -f1)
echo "gpu_done at $LINE"
sed -n "$((LINE-5)),$((LINE+30))p" "$F"
echo
echo "===== [5] mach time / MIN MAX 可用性 ====="
grep -n "mach_absolute_time\|absolutetime_to_nanoseconds\|#define MIN\|#define MAX" "$F" | head -12
echo
echo "===== [6] hfi_send 完整 ====="
sed -n '2230,2275p' "$F"
