#!/bin/bash
S=/root/star26/star-native
echo "=== kernel: who prints 'THE GPU STAYS ON' and what registers the service ==="
grep -rn 'THE GPU STAYS ON' $S --include=*.c --include=*.cpp | head -3
grep -rn 'AnnibaleGPUStart\|annibale_gpu_service\|stub service registered' $S --include=*.c --include=*.cpp --include=*.h --include=*.inc | head -12
echo
echo "=== userland sources that say 'no AnnibaleGPU service' ==="
grep -rn 'no AnnibaleGPU service' /root/star26/hackios-xnu-userland /root/star26/warsaw-ref /root/g11930-ref 2>/dev/null | head -3
echo
echo "=== the check around it ==="
grep -rn 'no AnnibaleGPU service' -B18 -A6 /root/star26/hackios-xnu-userland/tools/mesa/air/air_metal.c | head -50
echo
echo "=== kernel side: what AnnibaleGPUStart publishes ==="
sed -n '395,470p' /root/star26/star-native/iokit/Kernel/AnnibaleGPU.cpp
