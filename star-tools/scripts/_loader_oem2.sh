#!/bin/bash
cd /root/star26/hackios-xnu-kernel/xnuloader
grep -rn 'get_staged\|screenshot' --include=*.cpp --include=*.c --include=*.h . | head -8
echo "=== oem handlers ==="
grep -rn '"oem' --include=*.cpp . | head -20
</>
