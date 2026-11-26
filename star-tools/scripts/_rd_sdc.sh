#!/bin/bash
F=/root/star26/star-native/iokit/Kernel/StarDisplayCompat.cpp
echo "=== head 60 ==="
sed -n '1,60p' "$F"
echo
echo "=== is it in the build? ==="
grep -rn "StarDisplayCompat" /root/star26/star-native/iokit/Kernel/*.h /root/star26/star-native/iokit/Kernel/conf/* /root/star26/star-native/iokit/conf/* 2>/dev/null | head
grep -rn "StarDisplayCompat" /root/star26/star-native/BUILD/ 2>/dev/null | head -3
