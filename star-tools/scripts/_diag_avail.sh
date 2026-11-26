#!/bin/bash
AV=/root/theos/sdks/iPhoneOS16.5.sdk/usr/include/os/availability.h
echo "=== availability.h 78-100 ==="
sed -n '78,100p' "$AV"
echo "=== API_AVAILABLE define context ==="
grep -n 'define API_AVAILABLE\|ifndef API_AVAILABLE\|__API_AVAILABLE' "$AV" | head -20
echo "=== all os/availability.h on disk ==="
find /root/star26 -path '*os/availability.h' 2>/dev/null | head -10
echo "=== reconstructed/patched SDK availability? ==="
find /root /mnt/d/桌面 -path '*availability.h' 2>/dev/null | head -20
