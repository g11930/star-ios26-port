#!/bin/bash
S=/root/star26/star-native/iokit/Kernel
echo "=== AnnibaleGPU's selector table ==="
grep -n 'case 0x\|selector\|DRM_IOCTL\|dev_info\|DEV_INFO' $S/AnnibaleGPU*.inc $S/AnnibaleGPU.cpp 2>/dev/null | head -30
echo
echo "=== freedreno's dev info definition ==="
grep -rn 'FREEDRENO_DEV_INFO\|drm_freedreno_dev_info' /root/star26/hackios-xnu-userland/tools/mesa --include=*.h --include=*.c 2>/dev/null | head -8
</bash>
</
</bash>
