#!/bin/bash
L=/mnt/c/ios26/s63-staged.bin
echo "=== waitq-diag lines (unique patterns) ==="
strings "$L" | grep -oE 'waitq-diag kr=-?[0-9]+/-?[0-9]+ wq=0x[0-9a-f]+ zid=[0-9]+' | sort | uniq -c | sort -rn | head -30
echo ""
echo "=== launchd block (pass 1, first 30 lines) ==="
strings "$L" | tr '\n' ' ' | sed 's/StarMsgProbe:/\nStarMsgProbe:/g' | grep -A30 '=== launchd ===' | head -35
echo ""
echo "=== zid distribution across all passes ==="
strings "$L" | grep -oE 'zid=[0-9]+' | sort | uniq -c | sort -rn
echo ""
echo "=== kr code distribution ==="
strings "$L" | grep -oE 'waitq-diag kr=-?[0-9]+/-?[0-9]+' | sort | uniq -c | sort -rn
echo ""
echo "=== process count / services ==="
strings "$L" | grep -oE 'EXECDBG: loading [^ ]+' | sed 's/EXECDBG: loading //' | sort -u | wc -l
echo "=== PANIC ==="
strings "$L" | grep -iE 'panic \(|data abort|Kernel data' | grep -v cmdline | head -3
