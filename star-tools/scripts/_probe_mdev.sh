#!/bin/bash
S=/root/star26/hackios-xnu-userland/userland/src
echo "== find metal_dev source =="
find "$S" -name "*metal_dev*" -o -name "metal_dev*" 2>/dev/null | head
echo
echo "== its content =="
F=$(find "$S" -name "*metal_dev*" 2>/dev/null | head -1)
if [ -n "$F" ]; then wc -l "$F"; sed -n '1,90p' "$F"; fi
