#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "===== [A] annibale_gpu_times + submit (3700-3790) ====="
sed -n '3700,3790p' "$F"
echo
echo "===== [B] weak 桩 annibale_gpu_speed 位置 ====="
grep -rn "annibale_gpu_speed" /root/star26/star-native/bsd/dev/star/
echo
echo "===== [C] 报表调用点 AnnibaleGPUSubmit.inc ====="
grep -n -A6 "annibale_gpu_speed\|annibale_gpu_times\|speed" /root/star26/star-native/iokit/Kernel/AnnibaleGPUSubmit.inc 2>/dev/null | head -40
