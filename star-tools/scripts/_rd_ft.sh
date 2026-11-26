#!/bin/bash
F=/root/star26/star-native/iokit/Kernel/MiniFramebufferFlip.inc
echo "=== flip_target ==="
awk '/^flip_target/,/^}/' "$F"
echo
echo "=== flip_latch ==="
awk '/^flip_latch/,/^}/' "$F"
echo
echo "=== flip_ready (setup) ==="
awk '/^flip_ready/,/^}/' "$F"
