#!/bin/bash
H=/root/star26/star-native/bsd/sys/annibale_input.h
echo "===== [1] annibale_input.h 头尾 extern C ====="
head -50 "$H" | grep -n "extern\|ifdef\|__cplusplus"
echo "--- tail ---"
tail -20 "$H" | grep -n "extern\|endif\|__cplusplus"
echo
echo "===== [2] weak 桩 StarDisplayCompat.cpp:110-125 ====="
sed -n '108,126p' /root/star26/star-native/iokit/Kernel/StarDisplayCompat.cpp
echo
echo "===== [3] 报表调用 annibale_gpu_speed ====="
grep -rn "annibale_gpu_speed" /root/star26/star-native/iokit/ | head -10
echo
echo "===== [4] 报表里 mhz/changes 打印格式 ====="
grep -rn -B2 -A4 "speed changes\|GPU at\|annibale_gpu_speed" /root/star26/star-native/iokit/Kernel/AnnibaleGPUSubmit.inc 2>/dev/null | head -30
