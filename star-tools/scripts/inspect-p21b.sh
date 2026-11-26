#!/bin/bash
R=/root/star26/kbuild/xnu-12377.121.6
K=/root/star26/hackios-xnu-kernel
echo "=== adreno8.c 340-395 ==="
sed -n '340,395p' $R/bsd/dev/adreno8/adreno8.c
echo "=== ann_gpu_open users in userland ==="
grep -rn 'ann_gpu_open' $K/tools/userland-driver/ $K/src 2>/dev/null | head -20
echo "=== rwa_device_open softpath ==="
grep -rn 'RWA_SOFTWARE' $K/tools/mesa/air/air_metal.c | head -10
