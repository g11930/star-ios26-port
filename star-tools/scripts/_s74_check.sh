#!/bin/bash
L=/mnt/c/ios26/s74-log.bin
echo "===== sc= lines (unique) ====="
strings -n 6 "$L" | grep -o 'sc=[-0-9?]*\( kr=-[0-9]*\)\?' | sort | uniq -c
echo
echo "===== launchd T# lines with sc (all passes) ====="
strings -n 6 "$L" | grep 'StarMsgProbe' | grep -A3 '=== launchd ===' | head -60
echo
echo "===== context: T# line followed by sc line (uniq) ====="
strings -n 6 "$L" | grep -A1 'T#[0-9] st=' | grep -E 'T#|sc=' | head -60
