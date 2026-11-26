#!/bin/bash
R=/root/star26/star-native
echo "=== TUNABLE definition ==="
grep -rn "define TUNABLE\|TUNABLE(" "$R/iokit/Kernel/"*.h "$R/iokit/Kernel/MiniDrivers.h" 2>/dev/null | head -10
echo "--- search all ---"
grep -rn "define TUNABLE" "$R" 2>/dev/null | head -5
