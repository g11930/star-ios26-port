#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "===== tsens 相关行 ====="
grep -n -i "tsens\|temperature\|tsense\|therm" "$F" | head -30
echo "===== 3920-3970: 传感器区 ====="
sed -n '3920,3970p' "$F"
