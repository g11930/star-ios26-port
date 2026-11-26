#!/bin/bash
SDK=/root/star26/hackios-xnu-userland/userland/xnu-deps/26/sdk/iPhoneOS.sdk
echo "=== reconstructed SDK availability.h API_AVAILABLE (line 88-95) ==="
sed -n '88,95p' "$SDK/usr/include/os/availability.h" 2>&1
echo "=== patched? grep noop context ==="
grep -n 'define API_AVAILABLE' "$SDK/usr/include/os/availability.h" 2>&1 | head
echo "=== SDK Frameworks CoreFoundation header? ==="
ls "$SDK/System/Library/Frameworks/CoreFoundation.framework/Headers/CoreFoundation.h" 2>&1
echo "=== SDK System dir? ==="
ls -d "$SDK/System" 2>&1
echo "=== SDK usr/include count ==="
find "$SDK/usr/include" -type f 2>/dev/null | wc -l
echo "=== compare: build.sh expects which? look at handoff doc ==="
grep -rn 'availability\|reconstruct\|isysroot\|xnu-deps/26' /root/star26/*.md /root/star26/hackios-xnu-userland/docs/*.md 2>/dev/null | head -20
