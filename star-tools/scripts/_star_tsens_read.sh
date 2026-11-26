#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "===== 3920..3990 tsens 读取实现 ====="
sed -n '3920,3990p' "$F"
