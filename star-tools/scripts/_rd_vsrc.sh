#!/bin/bash
F=/root/star26/star-native/iokit/Kernel/MiniIOMobileFramebuffer.cpp
echo "=== vinfo occurrences ==="
grep -n "vinfo" "$F" | head -20
echo
echo "=== start() head: 430-500 ==="
sed -n '430,500p' "$F"
