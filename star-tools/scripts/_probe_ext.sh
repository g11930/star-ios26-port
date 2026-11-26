#!/bin/bash
B=/root/star26/hackios-xnu-userland/userland/build.sh
echo "== how the bundle is linked into the system image =="
grep -n "Library/Extensions" "$B" | head -12
echo
echo "== context around first hit =="
L=$(grep -n "Library/Extensions" "$B" | head -1 | cut -d: -f1)
if [ -n "$L" ]; then sed -n "$((L-14)),$((L+10))p" "$B"; fi
