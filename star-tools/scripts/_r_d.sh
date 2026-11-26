#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "===== 3728-3800: annibale_gpu_submit 完整 ====="
sed -n '3728,3800p' "$F"
