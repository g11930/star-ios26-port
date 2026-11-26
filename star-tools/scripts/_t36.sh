#!/bin/bash
K=/root/star26/star-native
echo "=== framebuffer sources ==="
grep -rln 'MiniIOMobileFramebuffer\|gpuexecute\|fb_flip' $K --include=*.c --include=*.h --include=*.cpp --include=*.inc 2>/dev/null | head -10
echo "=== flip function names ==="
grep -rn 'flip: ' $K --include=*.c* --include=*.inc 2>/dev/null | head -6