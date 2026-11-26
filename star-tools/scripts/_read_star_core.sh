#!/bin/bash
K=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "===== star: step_core_power 全函数 (2329-2425) ====="
sed -n '2329,2425p' "$K"
echo
echo "===== star: tsens 温度段 (3930-3985) ====="
sed -n '3930,3985p' "$K"
