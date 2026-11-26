#!/bin/bash
L=/mnt/c/ios26/s61d-staged.bin
echo "=== PANIC/ABORT ==="
strings "$L" | grep -iE 'panic|data abort|Kernel data|soak|debug panic|fatal' | head -10
echo "=== PROBE PROCS ==="
strings "$L" | grep -E 'StarMsgProbe: (pass|PROC|task)' | head -30
echo "=== PROBE WAIT/PEER (first 80) ==="
strings "$L" | grep -E 'StarMsgProbe:' | grep -vE 'pass |PROC|task ' | head -80
echo "=== PROBE COUNTS ==="
printf 'total lines : '; strings "$L" | grep -c 'StarMsgProbe:'
printf 'waitq owner : '; strings "$L" | grep -c 'peer='
printf 'not mach    : '; strings "$L" | grep -c 'not mach_msg-looking'
printf 'abnormal    : '; strings "$L" | grep -cE 'abnormal|dead|invalid'
echo "=== LAST PROBE ==="
strings "$L" | grep 'StarMsgProbe:' | tail -30
