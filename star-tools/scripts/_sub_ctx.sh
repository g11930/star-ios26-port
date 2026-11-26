#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "===== annibale_gpu_submit 当前行号 ====="
grep -n "^annibale_gpu_submit\|^annibale_gpu_worked\|^annibale_gpu_report" "$F" | head
echo "===== submit 前 15 行上下文 ====="
L=$(grep -n "^annibale_gpu_submit" "$F" | head -1 | cut -d: -f1)
sed -n "$((L-12)),$((L+2))p" "$F"
