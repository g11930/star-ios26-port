#!/bin/bash
P=/mnt/c/ios26/s94-live3.bin
echo "=== SpringBoard runningboard handshake / FBSystemShell ==="
grep -a "SpringBoard\[32" "$P" | tr -d '\0' | grep -iE "handshake|runningboard|FBSystemShell|assertion|attempt|timeout|shell" | tail -20
echo "=== all sbmetal26 / registration / default lines (s94) ==="
grep -aE "sbmetal26|registration device|registration completed|default_before|adopted native" "$P" | tr -d '\0' | head -25
echo "=== same in s90 for comparison ==="
grep -aE "sbmetal26|registration device|registration completed|default_before|adopted native" /mnt/c/ios26/s90-live.bin | tr -d '\0' | head -25
