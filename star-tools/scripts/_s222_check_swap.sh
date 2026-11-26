#!/bin/bash
echo "=== swapon ==="
swapons 2>/dev/null || swapon --show 2>/dev/null || cat /proc/swaps
echo "=== /proc/meminfo swap ==="
grep -i swap /proc/meminfo
echo "=== wsl config on windows side (via mount check) ==="
ls -la /mnt/c/Users/10110/.wslconfig 2>/dev/null && cat /mnt/c/Users/10110/.wslconfig 2>/dev/null || echo "no .wslconfig"
echo "=== disk free root ==="
df -h / | tail -1
