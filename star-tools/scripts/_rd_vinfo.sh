#!/bin/bash
F=/root/star26/star-native/iokit/Kernel/MiniIOMobileFramebuffer.cpp
echo "=== vinfo setup (480-560) ==="
sed -n '480,560p' "$F"
