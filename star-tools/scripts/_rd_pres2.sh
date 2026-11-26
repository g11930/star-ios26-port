#!/bin/bash
F=/root/star26/star-native/iokit/Kernel/MiniIOMobileFramebuffer.cpp
echo "=== grep presenter/settle ==="
grep -n "presenterMain\|::presenter\|::settle\|IOLockSleep" "$F"
echo
echo "=== body 520-660 ==="
sed -n '520,660p' "$F"
