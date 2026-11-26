#!/bin/bash
echo "===== annibale_input.h 声明 ====="
sed -n '75,100p' /root/star26/star-native/bsd/dev/star/annibale_input.h
echo "===== 全树搜 annibale_gpu_speed ====="
grep -rn "annibale_gpu_speed" /root/star26/star-native/ 2>/dev/null | head -20
echo "===== 全树搜 annibale_gpu_temperature ====="
grep -rn "annibale_gpu_temperature" /root/star26/star-native/ 2>/dev/null | head -20
echo "===== AnnibaleGPUSubmit.inc 报表调用 ====="
find /root/star26/star-native -name "AnnibaleGPUSubmit.inc" | head -3
