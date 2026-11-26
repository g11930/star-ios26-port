#!/bin/bash
# Final read-only checks for the gpt command: Android partition protection and the
# unchanged-size case.  `write` here is expected to be refused by the checks, so nothing
# reaches the disk.
export MSYS_NO_PATHCONV=1
A=/mnt/d/桌面/adb-fastboot/adb.exe

echo "=== plan userdata 180G: preview only, warn but not block ==="
"$A" shell "su -c 'starfs gpt plan 34 --size 180G'" 2>&1 | tr -d '\r'

echo
echo "=== write userdata: must be refused (Android system partition) ==="
"$A" shell "su -c 'starfs gpt write 34 --size 180G --name userdata --commit'" 2>&1 | tr -d '\r'

echo
echo "=== plan darwin 16G (unchanged): no spurious container warning ==="
"$A" shell "su -c 'starfs gpt plan 38 --size 16G'" 2>&1 | tr -d '\r'

echo
echo "=== GPT still intact after all of the above ==="
"$A" shell "su -c 'starfs gpt list --tsv | tail -4'" 2>&1 | tr -d '\r'
echo "=== DONE ==="
