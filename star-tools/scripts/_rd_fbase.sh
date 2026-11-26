#!/bin/bash
F=/root/star26/star-native/iokit/Kernel/MiniIOMobileFramebuffer.cpp
echo "=== fBase occurrences ==="
grep -n "fBase" "$F" | head -30
echo
echo "=== P34 sampling ==="
grep -n "P34" "$F" | head -20
