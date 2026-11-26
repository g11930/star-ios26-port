#!/bin/bash
cd /root/star26/star-native || exit 1
echo "=== git status (source tree) ==="
git status --porcelain 2>/dev/null | head -20
echo "=== files modified in last 20 min (source only) ==="
find . -name "*.c" -o -name "*.cpp" -o -name "*.h" -o -name "*.inc" 2>/dev/null | xargs ls -lt 2>/dev/null | head -8
