#!/bin/bash
F=/root/star26/star-native/iokit/Kernel/MiniIOMobileFramebuffer.cpp
echo "=== 966-1030 ==="
sed -n '966,1030p' "$F"
