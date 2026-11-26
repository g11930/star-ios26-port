#!/bin/bash
f=/mnt/c/ios26/s61c-staged.bin
echo "=== TAIL ==="
strings "$f" | grep -vE 'LaunchDaemons|\.plist|StarMsgProbe' | tail -30
echo "=== PANIC? ==="
strings "$f" | grep -iE 'panic|assert|PATCHER|unsolved|kernel_' | tail -12
echo "=== PROBE SUMMARY ==="
strings "$f" | grep 'StarMsgProbe' | head -8
