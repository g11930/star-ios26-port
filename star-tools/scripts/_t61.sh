#!/bin/bash
grep -rn "mount-phase" /root/star26/star-native --include=*.c --include=*.h 2>/dev/null | head -6
echo ---
grep -rn "not a platform binary" /root/star26/star-native --include=*.c --include=*.h 2>/dev/null | head -6
echo ---
grep -rn "userspace panic" /root/star26/star-native --include=*.c --include=*.h 2>/dev/null | head -12