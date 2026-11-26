#!/bin/bash
R=/root/star26/star-native
echo "=== annibale_frames_shown defs ==="
grep -rn "annibale_frames_shown" "$R" --include=*.c --include=*.cpp --include=*.inc --include=*.h 2>/dev/null | grep -v "\.bak"
echo
echo "=== present / flip / swap symbols ==="
grep -rn "setGammaTable\|swapComplete\|flushSubrange\|presentFrame\|framebufferPresent\|IOFBCurrentPixelPipe\|setAttributeForConnection" "$R/iokit/Kernel/MiniFramebufferDCS.inc" 2>/dev/null | head -20
echo
echo "=== MiniFramebufferDCS.inc function list ==="
grep -n "^[a-zA-Z_].*(\|^static .*(" "$R/iokit/Kernel/MiniFramebufferDCS.inc" 2>/dev/null | head -60
