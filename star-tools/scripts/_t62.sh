#!/bin/bash
sed -n '940,1010p' /root/star26/star-native/bsd/kern/kern_cs.c
echo "=== callers of cs_require_platform / platform check ==="
grep -rn "cs_require_platform\|task_require_platform\|platform_binary)" /root/star26/star-native/bsd --include=*.c --include=*.h 2>/dev/null | head -12