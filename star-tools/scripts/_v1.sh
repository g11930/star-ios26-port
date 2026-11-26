#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "===== 2310-2345: 新文件级 speeds 表 ====="
sed -n '2310,2345p' "$F"
echo
echo "===== step_core_power 内引用检查 ====="
grep -n "star_gpu_speeds\|star_speed_now\|star_speed_asked\|star_speed_floor\|star_speed_limit\|speeds\[" "$F" | head -25
