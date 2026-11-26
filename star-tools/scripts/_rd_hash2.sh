#!/bin/bash
F=/root/star26/star-native/iokit/Kernel/MiniFramebufferRows.inc
echo "=== hashRows 175-240 ==="
sed -n '175,240p' "$F"
