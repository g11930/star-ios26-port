#!/bin/bash
D=/root/star26/hackios-xnu-userland/userland/src/inject
echo "--- inject_sb26_layers.c head ---"
head -40 $D/inject_sb26_layers.c
echo "--- texture/IOSurface bits ---"
grep -n 'IOSurface\|newTexture\|contents\|CGImage' $D/inject_sb26_layers.c | head -20
</