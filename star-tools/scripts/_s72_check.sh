#!/bin/bash
# s72: extract StarMsgProbe output from the live staged log.
L=/mnt/c/ios26/s72-log.bin
echo "=== log size ==="
ls -l "$L"
echo
echo "=== pass markers ==="
strings -n 6 "$L" | grep -E 'StarMsgProbe: (pass|done|no target)' | head -40
echo
echo "=== all StarMsgProbe lines (first 220) ==="
strings -n 6 "$L" | grep 'StarMsgProbe' | head -220
