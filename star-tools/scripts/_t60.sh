#!/bin/bash
grep -rn 'is not a platform\|require_platform\|platform_binary (mount\|boot task' /root/star26/star-native/bsd/kern/*.c /root/star26/star-native/bsd/vfs/*.c 2>/dev/null | head -10
echo ---
grep -rn 'boot task' /root/star26/star-native --include=*.c --include=*.h 2>/dev/null | head -10