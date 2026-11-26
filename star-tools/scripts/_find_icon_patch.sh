#!/bin/bash
F=/root/star26/hackios-xnu-userland/userland/src/inject/inject_sb26.c
echo "=== file ==="
ls -la "$F"
wc -l "$F"
echo
echo "=== icon-related lines ==="
grep -n -i -E "shouldForceBitmapImages|software_icon|soft_icon|bitmap|Calendar|iconfill|icon_fill|iconservice" "$F" | head -60
