#!/bin/bash
F=/root/star26/star-native/iokit/Kernel/MiniFramebufferUserClient.inc
echo "=== fCallbacks / kFBNotifyVSync assignment ==="
grep -n "fCallbacks\|kFBNotify" "$F" | head -30
echo
echo "=== 210-245 (arm path) ==="
sed -n '210,245p' "$F"
