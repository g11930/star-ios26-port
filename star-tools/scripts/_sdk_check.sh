#!/bin/bash
R=/root/star26/hackios-xnu-userland
echo "=== xnu-deps tree ==="
ls -la "$R/xnu-deps/" 2>&1 | head -20
echo "=== find 26 sdk ==="
find "$R" -maxdepth 4 -type d -name 'iPhoneOS.sdk' 2>/dev/null
echo "=== find iOS26 CoreFoundation.h anywhere ==="
find /root/star26 -path '*CoreFoundation.framework/Headers/CoreFoundation.h' 2>/dev/null | head -5
echo "=== find xpc.h anywhere under star26 ==="
find /root/star26 -path '*xpc/xpc.h' 2>/dev/null | head -5
echo "=== DONE ==="
