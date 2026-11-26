#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "===== 2110-2135: HFI 常量与 perf_table 结构 ====="
sed -n '2110,2135p' "$F"
echo
echo "===== 2308-2330: core_khz 与函数前导 ====="
sed -n '2308,2330p' "$F"
