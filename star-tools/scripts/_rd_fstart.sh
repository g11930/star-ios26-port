#!/bin/bash
F=/root/star26/star-native/iokit/Kernel/MiniFramebufferFlip.inc
echo "=== flip_start ==="
awk '/^flip_start/,/^}$/' "$F"
echo
echo "=== flip_taken ==="
awk '/^flip_taken/,/^}$/' "$F"
