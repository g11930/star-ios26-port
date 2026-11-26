#!/bin/bash
D=/root/star26/hackios-xnu-userland/userland/src/inject
echo "--- files ---"
ls $D | head -25
echo "--- texture APIs referenced ---"
grep -rln 'newTexture\|MTLTexture\|replaceRegion\|IOSurface' $D | head -12
echo "--- CA layer / contents handling ---"
grep -rln 'contents\|CGImage\|CALayer' $D | head -10
</