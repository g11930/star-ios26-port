#!/bin/bash
f=/mnt/c/ios26/s61-staged.bin
echo "=== StarMsgProbe lines ==="
strings "$f" | grep -c 'StarMsgProbe' || true
echo "=== pass summary ==="
strings "$f" | grep -E 'StarMsgProbe: pass|done \(' | head -20
echo "=== target headers ==="
strings "$f" | grep 'StarMsgProbe: ===' | head -12
echo "=== backboardd waits ==="
strings "$f" | grep -A2 '=== backboardd' | head -40
