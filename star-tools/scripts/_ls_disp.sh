#!/bin/bash
R=/root/star26/star-native
echo "=== display related files ==="
ls -l "$R/bsd/dev/star/" 2>/dev/null | grep -i "disp\|fb\|dcs\|dsi\|dpu\|panel\|mipi" 
echo "=== iokit framebuffer ==="
ls -l "$R/iokit/Kernel/" 2>/dev/null | grep -i "fb\|disp\|dcs"
echo "=== grep core symbols ==="
grep -rln "star_display\|splash\|present\|flip" "$R/bsd/dev/star/" "$R/iokit/" 2>/dev/null | grep -v "\.bak" | head -20
