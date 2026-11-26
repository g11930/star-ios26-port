#!/bin/bash
S=/root/star26/star-native/iokit/Kernel
echo "=== current kMsmGetParam body ==="
sed -n '741,800p' $S/AnnibaleGPU.cpp
echo
echo "=== param constants defined here ==="
grep -rn 'kMsm\|MSM_PARAM\|PARAM_' $S/AnnibaleGPU.cpp $S/AnnibaleGPU*.inc 2>/dev/null | head -30
</bash>
</
</bash>
