#!/bin/bash
F=/root/star26/star-native/iokit/Kernel/MiniFramebufferRows.inc
echo "=== 230-345 ==="
sed -n '230,345p' "$F"
