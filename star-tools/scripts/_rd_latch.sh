#!/bin/bash
R=/root/star26/star-native/iokit/Kernel
F=$R/MiniIOMobileFramebuffer.cpp
echo "=== has_latch / latch_swap origin (880-965) ==="
sed -n '880,965p' "$F"
