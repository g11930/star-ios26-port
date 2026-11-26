#!/bin/bash
R=/root/star26/star-native/iokit/Kernel
echo "=== gRows usage ==="
grep -rn "gRows\|fRowHashRows\|fRowSeq\|fBufferSeq\|dirtyBand" "$R/MiniIOMobileFramebuffer.cpp" "$R/MiniFramebufferFlip.inc" "$R/MiniFramebufferSwap.h" 2>/dev/null | head -40
echo
echo "=== refreshHz ==="
grep -rn "refreshHz" "$R"/*.cpp "$R"/*.inc "$R"/*.h 2>/dev/null | head -10
echo "=== kFBRefreshHz ==="
grep -rn "kFBRefreshHz" "$R" | head -5
