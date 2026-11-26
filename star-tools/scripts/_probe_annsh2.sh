#!/bin/bash
F=/root/star26/hackios-xnu-userland/userland/src/apps/annsh.c
echo "== all commands =="
grep -nE 'strcmp\(argv\[0\], "' "$F" | sed 's/.*strcmp(argv\[0\], "\([a-z_]*\)".*/\1/' | tr '\n' ' '
echo
echo "== sleep / delay support =="
grep -n "sleep\|usleep\|-d \|delay" "$F" | head -15
echo
echo "== for_named signature =="
grep -n -A12 "^for_named" "$F" | head -30
