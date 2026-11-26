#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "=== annibale_gpu_done ==="
awk '/^annibale_gpu_done/,/^}/' "$F"
echo
echo "=== grep done markers ==="
grep -n "annibale_gpu_done\|gpuDone\|fence_done\|timestamp\|gpu_ready" "$F" | head -20
