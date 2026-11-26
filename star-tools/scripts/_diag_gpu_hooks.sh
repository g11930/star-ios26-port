#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "=== [1] busy counters available ==="
grep -n -E "RBBM_PERFCTR|GPU_BUSY|busy_masked|AO_GPU_CX_BUSY" "$F" | head -20
echo
echo "=== [2] periodic work / thread / timer in driver ==="
grep -n -E "kernel_thread|thread_create|IODispatchQueue|timer|timeout\(|nanotime|watch_seconds|sleep_us\(1000000" "$F" | head -30
echo
echo "=== [3] submit path hooks (where K90 pokes freq) ==="
grep -n -E "annibale_gpu_submit|gpu_submit|AnnibaleGPUSubmit|submit" "$F" | head -20
echo
echo "=== [4] AnnibaleGPU.cpp: submit + any freq hints ==="
grep -n -E "submit|Submit|freq|speed|busy" /root/star26/star-native/iokit/Kernel/AnnibaleGPU.cpp | head -30
echo
echo "=== [5] the keeper loop ('THE GPU STAYS ON') ==="
grep -n -B8 -A28 "THE GPU STAYS ON" "$F" | head -70
