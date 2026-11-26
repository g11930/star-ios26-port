#!/bin/bash
echo "===== 全树找 annibale_gpu_temperature 声明 ====="
grep -rn "annibale_gpu_temperature" /root/star26/star-native/ 2>/dev/null | grep -v "\.o:" | head -20
echo
echo "===== 全树找 annibale_gpu_speed 声明/weak ====="
grep -rn "annibale_gpu_speed" /root/star26/star-native/ 2>/dev/null | grep -v "\.o:" | head -20
