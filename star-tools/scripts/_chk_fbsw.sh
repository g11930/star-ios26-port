#!/bin/bash
R=/root/star26/star-native/iokit/Kernel
F=$R/MiniIOMobileFramebuffer.cpp
echo "=== TUNABLE list in MiniIOMobileFramebuffer.cpp ==="
grep -n "TUNABLE" "$F"
echo
echo "=== fb_rows / fb_diff in Rows.inc ==="
grep -n "fb_rows\|fb_diff\|gRows\|gDiff" "$R/MiniFramebufferRows.inc"
echo
echo "=== gDiff usage in main cpp ==="
grep -n "gDiff" "$F"
