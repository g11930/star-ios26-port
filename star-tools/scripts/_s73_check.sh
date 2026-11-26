#!/bin/bash
# s73: extract StarMsgProbe output from the live staged log (-show_pointers=1).
L=/mnt/c/ios26/s73-log.bin
echo "=== log size ==="
ls -l "$L"
echo
echo "=== launchd blocks (all passes) ==="
strings -n 6 "$L" | grep 'StarMsgProbe' | grep -A8 '=== launchd ===' | head -80
echo
echo "=== T# state lines only ==="
strings -n 6 "$L" | grep -o 'T#[0-9] st=[0-9a-f]* we=[0-9a-f]* wr=[0-9]* wq=0x[0-9a-f]* zid=[0-9]* susp=[0-9]*' | sort | uniq -c
