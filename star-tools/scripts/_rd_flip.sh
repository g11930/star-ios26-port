#!/bin/bash
R=/root/star26/star-native
echo "=== fb_flip TUNABLE ==="
grep -rn "fb_flip\|flip_target\|flip_present\|flip_start\|flip_whole\|flip_band\|flip_latch\|flip.ready\|flip.shown" "$R/iokit/Kernel/MiniFramebufferFlip.inc" | head -60
echo
echo "=== gProbe ==="
grep -rn "gProbe" "$R/iokit/Kernel/MiniIOMobileFramebuffer.cpp" | head -10
