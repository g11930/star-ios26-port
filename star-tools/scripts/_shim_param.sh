#!/bin/bash
D=/root/star26/hackios-xnu-kernel/tools/userland-driver
echo "=== get_param usage in shim ==="
grep -rn 'get_param\|GET_PARAM\|getParam\|0x14' $D/*.inc $D/*.m 2>/dev/null | head -20
echo "=== fd/msm ioctl helpers ==="
grep -rn 'MSM_PARAM\|DRM_IOCTL' $D 2>/dev/null | head -12
</>
