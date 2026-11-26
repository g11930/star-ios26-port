#!/bin/bash
cd /root/star26/hackios-xnu-kernel/xnuloader || exit 1
echo "=== files ==="
ls *.inc *.h 2>/dev/null | head -30
echo
echo "=== percent / progress symbols ==="
grep -rn "pct\|percent\|progress\|PROGRESS\|UI_BOOT_STEP\|milestone" *.inc *.h 2>/dev/null | head -40
