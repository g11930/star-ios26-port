#!/bin/bash
F=/root/star26/star-native/iokit/Kernel/MiniIOMobileFramebuffer.cpp
echo "=== 75-105 ==="
sed -n '75,105p' "$F"
