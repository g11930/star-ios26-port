#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "===== [1] speeds 表 + step_core_power 区 (2300-2460) ====="
sed -n '2300,2460p' "$F"
echo
echo "===== [2] tsens 读取实现 (grep) ====="
grep -n "tsens\|TSENS\|temperature\|tsen" "$F" | head -40
