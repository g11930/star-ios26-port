#!/bin/bash
R=/root/star26/star-native/iokit/Kernel
echo "=== P34 in all files ==="
grep -rn "P34" "$R" 2>/dev/null | head -20
echo
echo "=== the sampler function ==="
F=$(grep -rl "P34" "$R" 2>/dev/null | head -1)
echo "file: $F"
L=$(grep -n "P34" "$F" | head -1 | cut -d: -f1)
sed -n "$((L-45)),$((L+25))p" "$F"
