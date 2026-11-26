#!/bin/bash
F=/root/star26/star-native/iokit/Kernel/MiniIOMobileFramebuffer.cpp
echo "=== gTouchLat decl / read ==="
grep -n "gTouchLat\|touch_lat\|TL(" "$F" | head -20
echo
echo "=== present() around tl: s (830-870) ==="
sed -n '830,870p' "$F"
echo
echo "=== tl: l site (950-975) ==="
sed -n '948,975p' "$F"
echo
echo "=== tl: v + milestone (1030,1060) ==="
sed -n '1028,1060p' "$F"
