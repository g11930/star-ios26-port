#!/bin/bash
R=/root/star26/star-native
echo "=== annibale_gpu_ready definitions ==="
grep -rn "annibale_gpu_ready" "$R" --include=*.c --include=*.cpp --include=*.inc --include=*.h 2>/dev/null | grep -v "\.bak"
echo
echo "=== gpuWait ==="
grep -n "gpuWait" "$R/iokit/Kernel/AnnibaleGPU.cpp" | head -5
