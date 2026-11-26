#!/bin/bash
R=/root/star26/star-native/iokit/Kernel
F=$R/AnnibaleGPU.cpp
wc -l "$F"
echo "=== tl: f site + gpuWait ==="
grep -n "tl: f\|gpuWait\|fence\|Fence" "$F" | head -50
