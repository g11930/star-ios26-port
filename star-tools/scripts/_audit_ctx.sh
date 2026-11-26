#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "===== hfi_send 里的 hold() 定义 ====="
grep -n "^hold(\|hold(bool\|static.*hold" "$F" | head
echo "===== hfi_send 完整（含等待循环）====="
sed -n '2232,2290p' "$F"
echo "===== annibale_gpu_submit 谁调用、什么锁 ====="
grep -rn "annibale_gpu_submit" /root/star26/star-native/iokit/ /root/star26/star-native/bsd/ --include=*.cpp --include=*.inc --include=*.c 2>/dev/null | head
echo "===== AnnibaleGPU submit 调用上下文（锁）====="
grep -n -B8 -A4 "annibale_gpu_submit" /root/star26/star-native/iokit/Kernel/AnnibaleGPUSubmit.inc 2>/dev/null | head -40
