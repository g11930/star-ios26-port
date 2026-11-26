#!/bin/bash
R=/root/star26/kbuild/xnu-12377.121.6
echo "=== gGPUReported / gGPULock ==="
grep -n 'gGPUReported' $R/iokit/Kernel/AnnibaleGPU.cpp
echo "=== gGPULock decl ==="
grep -n 'gGPULock' $R/iokit/Kernel/AnnibaleGPU.cpp | head -5
echo "=== step_service callers ==="
grep -rn 'adreno8_step_service' $R/bsd/ 2>/dev/null
echo "=== AnnibaleGPUStart callers ==="
grep -rn 'AnnibaleGPUStart' $R/iokit/ $R/bsd/ 2>/dev/null
echo "=== externalMethod tail ==="
sed -n '760,812p' $R/iokit/Kernel/AnnibaleGPU.cpp
