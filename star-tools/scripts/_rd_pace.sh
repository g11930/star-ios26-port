#!/bin/bash
R=/root/star26/star-native/iokit/Kernel
ls -l "$R"/*.inc
echo "=== presenter location ==="
grep -n "presenterMain\|::presenter\|::settle\|IOLockSleep" "$R"/MiniFramebufferPacing.inc "$R"/MiniFramebufferSwap.h 2>/dev/null | head -20
