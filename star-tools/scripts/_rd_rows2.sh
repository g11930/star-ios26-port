#!/bin/bash
R=/root/star26/star-native/iokit/Kernel
echo "=== gRows / fb_rows TUNABLE ==="
grep -rn "gRows\|fb_rows\|fRowHashRows" "$R"/*.cpp "$R"/*.inc 2>/dev/null | head -20
echo
echo "=== MiniFramebufferRows.inc body ==="
sed -n '1,120p' "$R/MiniFramebufferRows.inc"
