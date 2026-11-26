#!/bin/bash
R=/root/star26/star-native
echo "=== pac_emu sources ==="
grep -rln "pac_emu" "$R" 2>/dev/null | grep -v "\.bak" | head -10
echo
echo "=== log line site ==="
grep -rn "software PAuth active" "$R" 2>/dev/null | grep -v "\.bak"
