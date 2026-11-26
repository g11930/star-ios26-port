#!/bin/bash
F=/root/star26/star-native/iokit/Kernel/MiniFramebufferRows.inc
echo "=== 150-270 ==="
sed -n '150,270p' "$F"
