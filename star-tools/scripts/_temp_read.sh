#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "===== 3930-3980: 温度读取实现 ====="
sed -n '3930,3980p' "$F"
