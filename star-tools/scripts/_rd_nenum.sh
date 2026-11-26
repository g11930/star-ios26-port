#!/bin/bash
R=/root/star26/star-native
echo "=== kFBNotify enum ==="
grep -rn "kFBNotify" "$R/iokit/Kernel/"*.h "$R/iokit/Kernel/"*.cpp "$R/iokit/Kernel/"*.inc 2>/dev/null | grep -i "enum\|= *[0-9]\|kFBNotifyTypes" | head -20
echo
echo "=== find the enum block ==="
F=$(grep -rln "kFBNotifyVSync *=" "$R" 2>/dev/null | grep -v "\.bak" | head -1)
echo "file: $F"
[ -n "$F" ] && grep -n -A 20 "kFBNotifyVSync *=" "$F" | head -30
