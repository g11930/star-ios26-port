#!/bin/bash
grep -n 'oem' /root/star26/hackios-xnu-kernel/xnuloader/platform_private.h | head -20
echo "=== command table ==="
grep -rn 'oem log\|"log"\|command' /root/star26/hackios-xnu-kernel/xnuloader/*.cpp 2>/dev/null | head -15
</>
