#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "===== 温度相关符号 ====="
grep -n -i "tsens\|temperature\|temp" "$F" | head -30
