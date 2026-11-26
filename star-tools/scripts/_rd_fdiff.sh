#!/bin/bash
F=/root/star26/star-native/iokit/Kernel/MiniIOMobileFramebuffer.cpp
echo "=== fDiff decl & uses ==="
grep -n "fDiff\|gFBScale\|fbscale" "$F"
echo
echo "=== 520-560 ==="
sed -n '520,560p' "$F"
