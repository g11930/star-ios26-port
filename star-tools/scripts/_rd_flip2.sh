#!/bin/bash
R=/root/star26/star-native/iokit/Kernel
echo "=== flip_target / flip_latch / flip struct ==="
sed -n '1,140p' "$R/MiniFramebufferFlip.inc"
