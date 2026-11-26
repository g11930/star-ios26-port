#!/bin/bash
S=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "===== star speeds 表定义（结构/hz/bus）====="
grep -n -E "adreno_speeds|speeds\[\]|struct.*speed|gx_hz|speed_hz|\.bus|\.hz" "$S" | head -30
echo
echo "===== 2390-2410: 投票消息格式（step 里发 speed wanted）====="
sed -n '2388,2410p' "$S"
echo
echo "===== star 有没有 retired/busy 计数 ====="
grep -n -E "retired|retired_total|busy_seen|busy_ns|worked" "$S" | head -20
echo
echo "===== star 有没有温度读取 ====="
grep -rn "annibale_gpu_temperature\|gpu_temperature\|temperature" /root/star26/star-native/bsd/dev/star/ /root/star26/star-native/bsd/sys/annibale_input.h 2>/dev/null | head -20
