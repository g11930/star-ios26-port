#!/bin/bash
F=/root/star26/star-native/iokit/Kernel/MiniIOMobileFramebuffer.cpp
echo "=== 1080-1140 ==="
sed -n '1080,1140p' "$F"
echo
echo "=== 760-800 (thread path) ==="
sed -n '760,800p' "$F"
