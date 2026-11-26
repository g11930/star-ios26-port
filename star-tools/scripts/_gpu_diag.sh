#!/bin/bash
echo "########## 1. 我们树里 GPU/显示相关实现 ##########"
find /root/star26/star-native -iname "*gpu*" -o -iname "*metal*" -o -iname "*adreno*" 2>/dev/null | grep -vE "BUILD/" | head -30
echo
echo "--- AnnibaleGPU stub 位置 ---"
grep -rln "AnnibaleGPU\|stub service registered" /root/star26/star-native 2>/dev/null | grep -vE "BUILD/" | head -10
echo
echo "########## 2. s71 日志里的 GPU/metal/surface 相关 ##########"
grep -aiE "GPU|metal|MTL|surface|IOSurface|render|frame|softpipe|adreno|WindowServer|backlight|framebuffer" /mnt/c/ios26/s71-log.bin | grep -viE "cmdline|boot-args|EXECDBG|image |\+image|plist|library insertion" | head -50
echo
echo "########## 3. 之前 s64 残留日志里的 softpipe 消息（确认是否 GPU 卡点） ##########"
grep -aiE "softpipe|half lowering|ALU fmax|llvmpipe|gallium|shader|SPIR" /mnt/c/ios26/s64-logdump.bin 2>/dev/null | head -20
echo
echo "########## 4. dada/warsaw 的 GPU 驱动文件 ##########"
grep "^diff --git" /root/ref/dada/kernel/xnu-12377.121.6-dada.patch | grep -iE "gpu|adreno|metal|drm|msm" | sed 's#diff --git a/##; s# b/.*##' | head -30
echo "warsaw:"
ls /root/ref/warsaw/xnu/patches/ | grep -iE "gpu|adreno|metal|drm"
