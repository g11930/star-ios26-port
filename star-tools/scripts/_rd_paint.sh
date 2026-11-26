#!/bin/bash
F=/root/star26/star-native/iokit/Kernel/MiniIOMobileFramebuffer.cpp
echo "=== TUNABLE list ==="
grep -n "static TUNABLE" "$F"
echo
echo "=== gPaint / gDiff / gProbe context (215-240) ==="
sed -n '215,240p' "$F"
