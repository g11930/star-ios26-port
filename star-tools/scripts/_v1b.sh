#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "===== 检查残留 speeds[] 引用 ====="
grep -n "[^_]speeds\[\|\bspeeds\b" "$F" | head
echo "===== 2410-2425: speed 选择区 ====="
sed -n '2405,2425p' "$F"
