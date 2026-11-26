#!/bin/bash
echo "===== star 全树搜 annibale_gpu_speed / gpu_speed ====="
grep -rn "annibale_gpu_speed\|gpu_speed" /root/star26/star-native/ 2>/dev/null | grep -v ".s216-pre" | head -30
echo
echo "===== star_platform_stubs.c 内容 ====="
cat /root/star26/star-native/bsd/dev/star/star_platform_stubs.c 2>&1 | head -60
echo
echo "===== K90 ref2 里有没有 annibale 调频桩 ====="
grep -rn "gpu_speed\|annibale_gpu_speed" /root/ref2/annibale-kernel/ 2>/dev/null | head -20
