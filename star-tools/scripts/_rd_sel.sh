#!/bin/bash
R=/root/star26/star-native/iokit/Kernel
echo "=== kFBMethod enum in UserClient.inc ==="
sed -n '50,145p' "$R/MiniFramebufferUserClient.inc"
