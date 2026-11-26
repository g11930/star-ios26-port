#!/bin/bash
L=/mnt/c/ios26/s61d-staged.bin
echo "=== PROC COUNT ==="
strings "$L" | grep -oE 'EXECDBG: loading [^ ]+' | sed 's/EXECDBG: loading //' | sort -u | wc -l
echo "=== SURFACE / FRAME ==="
strings "$L" | grep -E 'created surface|render pipelines|first_frame|swap ' | head -8
echo "=== CACHE / BOOT ==="
strings "$L" | grep -E 'Unable to load cache|Cache sent to launchd|Early boot complete' | head -5
echo "=== SPAWN FAIL ==="
strings "$L" | grep -iE 'fail.*spawn|spawn.*fail|cannot spawn|posix_spawn.*err|launchd.*error' | head -10
echo "=== KEY SERVICES ==="
for s in cfprefsd configd securityd keybagd lsd backboardd SpringBoard logd; do
  printf '%-14s ' "$s"
  strings "$L" | grep -c "EXECDBG: loading [^ ]*$s"
done
echo "=== HEARTBEAT LAST ==="
strings "$L" | grep -E 'say (9|17|33) trace' | tail -4
