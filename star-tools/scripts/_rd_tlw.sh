#!/bin/bash
F=/root/star26/star-native/iokit/Kernel/MiniFramebufferUserClient.inc
echo "=== context around tl: w (190-250) ==="
sed -n '185,250p' "$F"
