#!/bin/bash
R=/root/star26/star-native
echo "=== loader_log_putc declarations ==="
grep -rn "loader_log_putc" "$R" --include=*.c --include=*.h --include=*.cpp --include=*.inc 2>/dev/null | grep -v "\.bak" | head -20
