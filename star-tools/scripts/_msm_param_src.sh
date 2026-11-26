#!/bin/bash
U=/root/star26/hackios-xnu-userland/userland/src
echo "=== msm param constants in shim ==="
grep -rn 'MSM_PARAM\|MSM_INFO\|0x14' $U --include=*.c --include=*.m --include=*.inc --include=*.h 2>/dev/null | grep -i 'param\|0x14' | head -20
</