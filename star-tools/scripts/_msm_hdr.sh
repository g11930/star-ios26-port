#!/bin/bash
echo "=== msm_drm.h present anywhere ==="
find /root -name 'msm_drm.h' 2>/dev/null | head -5
echo "=== its param list ==="
F=$(find /root -name 'msm_drm.h' 2>/dev/null | head -1)
[ -n "$F" ] && grep -n 'MSM_PARAM' $F | head -30
</>
