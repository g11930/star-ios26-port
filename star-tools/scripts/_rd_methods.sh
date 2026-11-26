#!/bin/bash
F=/root/star26/star-native/iokit/Kernel/MiniFramebufferUserClient.inc
echo "=== method trace print + selector table ==="
sed -n '236,300p' "$F"
echo
echo "=== gFBSelectorNames or similar ==="
grep -n "gFBCalls\|Names\[\]" "$F" | head -10
