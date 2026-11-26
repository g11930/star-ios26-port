#!/bin/bash
R=/root/star26/star-native
echo "=== annibale_tl definitions ==="
grep -rn "annibale_tl" "$R" --include=*.c --include=*.cpp --include=*.h --include=*.inc 2>/dev/null | grep -v "\.bak" | head -30
