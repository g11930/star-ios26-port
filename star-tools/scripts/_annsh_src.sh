#!/bin/bash
S=/root/star26/hackios-xnu-userland/userland/src/apps/annsh.c
sed -n '1,40p' $S
echo "--- builtins ---"
grep -n 'strcmp(name' $S | head -20
</