#!/bin/bash
S=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "===== annibale_gpu_speed 函数定义 ====="
grep -n "annibale_gpu_speed\|gpu_speed" "$S"
echo
echo "===== submit 函数定义 ====="
grep -n -E "^[a-zA-Z].*submit|static.*submit|void.*submit|int.*submit" "$S"
echo
echo "===== 找所有 static 函数名，看是否有调频桩 ====="
grep -n -E "^static .*\(" "$S" | head -60
