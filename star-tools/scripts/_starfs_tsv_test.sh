#!/bin/bash
# Verify the two things the WebUI depends on: machine-readable partition output, and the
# APFS container floor refusing a range that would cut the container.
export MSYS_NO_PATHCONV=1
A=/mnt/d/桌面/adb-fastboot/adb.exe

echo "=== gpt list --tsv (the format the WebUI parses) ==="
"$A" shell "su -c 'starfs gpt list --tsv'" 2>&1 | tr -d '\r' | tail -6
echo
echo "column count on the last line:"
"$A" shell "su -c 'starfs gpt list --tsv | tail -1 | awk -F\"\\t\" \"{print NF}\"'" 2>&1 | tr -d '\r'

echo
echo "=== plan 36 to 2G: below the container floor, must be REFUSED ==="
"$A" shell "su -c 'starfs gpt plan 36 --size 2G'" 2>&1 | tr -d '\r'

echo
echo "=== plan 36 to 4G: above the container, allowed with a warning ==="
"$A" shell "su -c 'starfs gpt plan 36 --size 4G'" 2>&1 | tr -d '\r' | tail -8

echo
echo "=== plan 38 to 16G: identical size, should pass cleanly ==="
"$A" shell "su -c 'starfs gpt plan 38 --size 16G'" 2>&1 | tr -d '\r'
echo "=== DONE (nothing written) ==="
