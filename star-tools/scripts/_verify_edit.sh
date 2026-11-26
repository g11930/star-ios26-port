#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "===== 行数 / md5 ====="
wc -l "$F"; md5sum "$F"
echo "===== 新符号定义计数（应各为 1）====="
for s in annibale_gpu_speed annibale_gpu_temperature star_gpu_speed_tick; do
    printf "%-28s %s\n" "$s" "$(grep -c "^$s" "$F")"
done
echo "===== tick 调用点 ====="
grep -n "star_gpu_speed_tick" "$F"
echo "===== 是否有 speeds[ 残留（应只在注释）====="
grep -n "speeds\[" "$F" | grep -v "star_gpu_speeds" | head
echo "===== 括号平衡粗检（函数体区间）====="
LINE=$(grep -n "^star_gpu_speed_tick" "$F" | cut -d: -f1)
echo "tick at $LINE"
sed -n "${LINE},$((LINE+105))p" "$F" | grep -c "^}"
