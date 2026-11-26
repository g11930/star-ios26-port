#!/bin/bash
T=/root/star26/star-native
echo "=== A. star-native git status (未提交改动) ==="
cd $T 2>/dev/null && git status --short 2>&1 | head -40
echo "--- git log -3 ---"
cd $T 2>/dev/null && git log --oneline -3 2>&1 | head
echo
echo "=== B. 全 /root/star26 二进制/文本搜 kAcceleratorPluginNameKey ==="
grep -rl 'kAcceleratorPluginNameKey\|AcceleratorPluginName' /root/star26 /root/star26-deps 2>/dev/null | head -20
echo
echo "=== C. 搜 IOAcceleratorES 字面量 ==="
grep -rn 'IOAcceleratorES' $T --include=*.c --include=*.cpp --include=*.h 2>/dev/null | grep -v BUILD | head -20
echo
echo "=== D. star 私有 GPU/sgx 服务发布点 ==="
grep -rn 'IOAccelerator\|"sgx"\|publishService\|registerService' $T/iokit/Kernel/AnnibaleGPU.cpp 2>/dev/null | head -40
echo
echo "=== E. AnnibaleGPU.cpp 开头 1-120 ==="
awk 'NR>=1 && NR<=120 {printf "%6d  %s\n", NR, $0}' $T/iokit/Kernel/AnnibaleGPU.cpp
echo "=== DONE ==="
