#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "===== 调频 tick 全文 ====="
sed -n '3800,3935p' "$F"
