#!/bin/bash
R=/root/star26/star-native/iokit/Kernel
F=$R/MiniFramebufferUserClient.inc
echo "=== vsync-related functions ==="
grep -n "VSync\|vsync" "$F" | head -40
echo
echo "=== armVSync body ==="
sed -n "$(grep -n '::armVSync' "$F" | head -1 | cut -d: -f1),+55p" "$F"
