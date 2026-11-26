#!/bin/bash
F=/root/star26/hackios-xnu-kernel/xnuloader/loader_05_layout_run_kernel.inc
echo "=== 570-625 ==="
sed -n '570,625p' "$F"
echo
echo "=== SCREEN struct / fb_base usage ==="
grep -rn "SCREEN\." /root/star26/hackios-xnu-kernel/xnuloader/*.inc /root/star26/hackios-xnu-kernel/xnuloader/*.c 2>/dev/null | grep -v "\.pre-" | head -20
