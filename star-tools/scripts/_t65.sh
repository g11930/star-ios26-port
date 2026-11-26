#!/bin/bash
grep -rn "mount-phase\|not a platform binary" /root/star26 --include=*.c --include=*.m --include=*.cpp --include=*.inc --include=*.h 2>/dev/null | head -8
echo "=== shim sources ==="
ls /root/star26/*/userland 2>/dev/null | head
find /root/star26 -maxdepth 4 -name '*annibale*.c' -o -maxdepth 4 -name '*annibale*.m' 2>/dev/null | head -8