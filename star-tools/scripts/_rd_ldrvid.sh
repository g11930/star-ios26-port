#!/bin/bash
L=/root/star26/hackios-xnu-kernel/xnuloader
ls "$L" 2>/dev/null | head -20
echo "=== v_baseAddr in loader ==="
grep -rn "v_baseAddr\|Video\.\|bootArgs->Video\|video.v_" "$L" --include=*.c --include=*.h 2>/dev/null | head -25
