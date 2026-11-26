#!/bin/bash
F=/root/star26/star-native/iokit/Kernel/AnnibaleGPU.cpp
echo "=== 240-340 ==="
sed -n '240,340p' "$F"
echo
echo "=== gGPUReported ==="
grep -n "gGPUReported" "$F"
