#!/bin/bash
cd /root/star26/star-native
echo "=== kern.annibale.* sysctls in kernel ==="
grep -rn 'kern.annibale' --include=*.c bsd osfmk | head -12
echo "=== Threads file? ==="
ls bsd/dev/star | grep -i threads
</>
