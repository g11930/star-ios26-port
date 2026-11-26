#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
L=$(grep -n "^annibale_gpu_submit" "$F" | head -1 | cut -d: -f1)
echo "submit at line $L"
sed -n "$((L)),$((L+30))p" "$F"
