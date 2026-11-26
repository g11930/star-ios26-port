#!/bin/bash
R=/root/star26/star-native/iokit/Kernel
echo "=== vsync in UserClient.inc ==="
grep -n "vsync\|VSync\|kFBNotify\|armVSync\|vsyncFired" "$R/MiniFramebufferUserClient.inc" | head -40
echo
echo "=== vsync body ==="
sed -n "/^IOMobileFramebufferUserClient::armVSync/,/^}/p" "$R/MiniFramebufferUserClient.inc"
echo "--- vsync() ---"
sed -n "/^IOMobileFramebufferUserClient::vsync/,/^}/p" "$R/MiniFramebufferUserClient.inc"
echo "--- vsyncFired ---"
sed -n "/^IOMobileFramebufferUserClient::vsyncFired/,/^}/p" "$R/MiniFramebufferUserClient.inc"
