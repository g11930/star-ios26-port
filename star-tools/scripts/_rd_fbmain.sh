#!/bin/bash
F=/root/star26/star-native/iokit/Kernel/MiniIOMobileFramebuffer.cpp
wc -l "$F"
echo "=== TUNABLE / boot-arg ==="
grep -n "TUNABLE" "$F"
echo "=== swap/present functions ==="
grep -n "fSwapsShown\|Swap\|swap\|present\|Present\|flip\|Flip" "$F" | head -50
