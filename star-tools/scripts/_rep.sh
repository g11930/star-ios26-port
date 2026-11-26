#!/bin/bash
echo "===== AnnibaleGPUSubmit.inc 报表区 ====="
sed -n '205,245p' /root/star26/star-native/iokit/Kernel/AnnibaleGPUSubmit.inc
echo
echo "===== AnnibaleGPU.cpp 里 annibale_gpu_submit 调用 ====="
grep -n "annibale_gpu_submit\|annibale_gpu_worked" /root/star26/star-native/iokit/Kernel/AnnibaleGPU.cpp | head
