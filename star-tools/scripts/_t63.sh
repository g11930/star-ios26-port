#!/bin/bash
grep -rn "platform" /root/star26/star-native/bsd/vfs/*.c 2>/dev/null | head -12
echo "=== star_cs knobs ==="
grep -rn "star_cs" /root/star26/star-native --include=*.c --include=*.h 2>/dev/null | head -12