#!/bin/bash
S=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "===== star perf 表结构 gpu[].vote / bus vote ====="
grep -n -E "hfi_perf_table|struct hfi_gpu|gpu\[|vote|acd" "$S" | sed -n '1,40p'
echo
echo "===== K90 minimum DCVS vote (670-695) ====="
sed -n '670,695p' /root/ref2/annibale-kernel/xnu/files/bsd/dev/adreno8/adreno8_hfi.c
echo
echo "===== star annibale_gpu_temperature 定义位置 ====="
grep -rn "annibale_gpu_temperature" /root/star26/star-native/ 2>/dev/null | grep -v "annibale_input.h" | head
echo
echo "===== star hfi_send 实现 (2236-2270) ====="
sed -n '2236,2275p' "$S"
