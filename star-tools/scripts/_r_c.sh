#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "===== 3250-3270: gpu_ticks 声明 ====="
sed -n '3250,3270p' "$F"
echo
echo "===== 3690-3730: 忙计数累加与 gpu_times + submit 开头 ====="
sed -n '3690,3730p' "$F"
