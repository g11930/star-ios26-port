#!/bin/bash
K=/root/star26/star-native/iokit/Kernel
echo "=== frame-stat boot args ==="
grep -rn 'glframes\|fbstat\|frame_ms\|fps' $K/*.cpp $K/*.inc 2>/dev/null | head -20
echo "=== frames_shown uses ==="
grep -rn 'annibale_frames_shown' /root/star26/star-native --include=*.c --include=*.cpp --include=*.inc --include=*.h | head -10