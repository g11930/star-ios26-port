#!/bin/bash
echo "===== star: StarDisplayCompat.cpp weak 声明 (110-125) ====="
sed -n '110,125p' /root/star26/star-native/iokit/Kernel/StarDisplayCompat.cpp
echo
echo "===== star: AnnibaleGPU.cpp 声明 (70-80) ====="
sed -n '70,80p' /root/star26/star-native/iokit/Kernel/AnnibaleGPU.cpp
echo
echo "===== star: annibale_gpu_worked 声明在哪（看是否在头文件） ====="
grep -rn "annibale_gpu_worked\|annibale_gpu_speed" /root/star26/star-native/ --include="*.h" --include="*.hpp" 2>/dev/null | head
echo
echo "===== star: 看 annibale_adreno_minute 在哪被调用/注册 ====="
grep -rn "annibale_adreno_minute" /root/star26/star-native/ 2>/dev/null | head
echo
echo "===== star: hfi_send 签名 (2236-2260) ====="
sed -n '2236,2260p' /root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo
echo "===== star: rail_vote 函数（改档时需要重算 vote） ====="
grep -n -A25 "^rail_vote\|static bool rail_vote\|bool rail_vote" /root/star26/star-native/bsd/dev/star/annibale_adreno.c | head -35
