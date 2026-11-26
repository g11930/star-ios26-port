#!/bin/bash
R=/root/star26/star-native
echo "=== who prints 'star truth' ==="
grep -rn "star truth" "$R" --include=*.c --include=*.cpp --include=*.h --include=*.inc 2>/dev/null | grep -v "\.bak"
echo
echo "=== who fills vinfo (v_baseaddr / v_physaddr) ==="
grep -rn "v_baseaddr\|v_physaddr" "$R" --include=*.c --include=*.cpp --include=*.h --include=*.inc 2>/dev/null | grep -v "\.bak" | head -30
