#!/bin/bash
R=/root/star26/star-native
echo "=== search for pac patching ==="
grep -rn "0xd65f0bff\|0xd65f0fff\|retab\|RETAB" "$R" --include=*.c --include=*.cpp --include=*.h 2>/dev/null | grep -v "\.bak" | head -20
echo
echo "=== files mentioning pac (not sleh) ==="
grep -rln "pac_emu\|FEAT_PAuth\|pac_disabled" "$R/osfmk" "$R/bsd" "$R/pexpert" --include=*.c --include=*.h --include=*.cpp 2>/dev/null | grep -v "\.bak" | head -15
