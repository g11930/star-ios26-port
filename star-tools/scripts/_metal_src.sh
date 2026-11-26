#!/bin/bash
cd /root/star26/star-native
echo "--- userland tree ---"
ls userland/src/inject 2>/dev/null | head -20
echo "--- metal shim sources ---"
grep -rln 'newTextureWithDescriptor\|MTLDevice\|replaceRegion' userland/src 2>/dev/null | head -10
</