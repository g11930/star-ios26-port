#!/bin/bash
L=/root/star26/hackios-xnu-kernel/xnuloader
echo "=== Video / framebuffer in loader ==="
grep -rn "Video\|v_rowBytes\|v_width\|v_height\|v_depth\|0xEA600000\|EA600000" "$L" --include=*.c --include=*.h --include=*.inc 2>/dev/null | grep -v "\.pre-" | head -30
