#!/bin/bash
set -u
U=/root/star26/hackios-xnu-userland
echo "== exec_inject in userland =="
grep -rn "exec_inject" "$U" --include=*.c --include=*.h 2>/dev/null | head -20
echo
echo "== inject list / dylib names in init.c =="
grep -n -B4 -A30 "exec_inject" "$U/userland/src/boot/init.c" 2>/dev/null | head -60
echo
echo "== kernel side =="
grep -rn "exec_inject" /root/star26/star-native/bsd /root/star26/star-native/osfmk 2>/dev/null | head -20
