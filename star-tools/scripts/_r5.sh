#!/bin/bash
echo "===== [A] StarDisplayCompat.cpp weak 桩 (100-135) ====="
sed -n '100,135p' /root/star26/star-native/iokit/Kernel/StarDisplayCompat.cpp
echo
echo "===== [B] annibale_input.h 声明区 (115-145) ====="
sed -n '115,145p' /root/star26/star-native/bsd/sys/annibale_input.h
echo
echo "===== [C] AnnibaleGPU.cpp 声明 (70-80) ====="
sed -n '70,80p' /root/star26/star-native/iokit/Kernel/AnnibaleGPU.cpp
echo
echo "===== [D] annibale_gpu_temperature 声明与引用 ====="
grep -rn "annibale_gpu_temperature" /root/star26/star-native/ 2>/dev/null | grep -v ".o:" | head
