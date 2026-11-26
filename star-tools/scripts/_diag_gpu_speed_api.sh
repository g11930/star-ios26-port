#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "=== impl of annibale_gpu_speed ==="
grep -n -B10 -A45 "annibale_gpu_speed" "$F" | head -90
echo
echo "=== callers in AnnibaleGPU.cpp ==="
grep -n -B6 -A18 "annibale_gpu_speed" /root/star26/star-native/iokit/Kernel/AnnibaleGPU.cpp | head -60
echo
echo "=== any existing HFI vote after start (message 30 re-send) ==="
grep -n -E "HFI_GX_BW_PERF_VOTE|vote\[" "$F" | head -20
