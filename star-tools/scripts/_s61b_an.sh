#!/bin/bash
f=/mnt/c/ios26/s61b-staged.bin
echo "=== counts ==="
strings "$f" | grep -c 'StarMsgProbe'
echo "=== unique WAIT shapes (backboardd) ==="
strings "$f" | grep -A3 '=== backboardd' | grep 'WAIT' | sort -u | head -10
echo "=== unique WAIT shapes (SpringBoard) ==="
strings "$f" | grep -A5 '=== SpringBoard' | grep 'WAIT' | sort -u | head -10
echo "=== unique WAIT shapes (launchd) ==="
strings "$f" | grep -A9 '=== launchd' | grep -E 'WAIT|peer=' | sort -u | head -14
echo "=== all peer lines ==="
strings "$f" | grep 'peer=' | sort | uniq -c | sort -rn | head -12
