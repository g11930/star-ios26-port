#!/bin/bash
echo "===== annibale_adreno.c 头部 includes ====="
sed -n '1,40p' /root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "===== weak 桩完整内容 ====="
sed -n '108,125p' /root/star26/star-native/iokit/Kernel/StarDisplayCompat.cpp
echo "===== AnnibaleGPUSubmit.inc 报表上下文 ====="
sed -n '210,240p' /root/star26/star-native/iokit/Kernel/AnnibaleGPUSubmit.inc
