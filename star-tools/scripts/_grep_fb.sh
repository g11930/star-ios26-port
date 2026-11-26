#!/bin/bash
R=/root/star26/star-native
echo "=== fb_dcs / fb_flip / fb_dim definitions ==="
grep -rn "fb_dcs\|fb_flip\|fb_dim" "$R" --include=*.c --include=*.h 2>/dev/null | grep -v "\.bak" | head -40
