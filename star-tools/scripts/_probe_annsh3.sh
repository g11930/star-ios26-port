#!/bin/bash
F=/root/star26/hackios-xnu-userland/userland/src/apps/annsh.c
echo "== main() =="
L=$(grep -n "^main(" "$F" | head -1 | cut -d: -f1)
echo "main at $L"
if [ -n "$L" ]; then awk -v s="$L" 'NR>=s && NR<=s+70' "$F"; fi
