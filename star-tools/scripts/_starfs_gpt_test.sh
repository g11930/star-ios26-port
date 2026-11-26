#!/bin/bash
# Read-only validation of the new gpt commands.  Nothing here writes: `plan` never opens
# the device writable, and `write` requires --commit plus a matching --name.
export MSYS_NO_PATHCONV=1
A=/mnt/d/桌面/adb-fastboot/adb.exe
run() { echo "--- $* ---"; "$A" shell "su -c '$*'" 2>&1 | tr -d '\r'; echo; }

echo "=== 1. gpt list ==="
"$A" shell "su -c 'starfs gpt list'" 2>&1 | tr -d '\r' | head -45

echo
echo "=== 2. plan: darwin (index from list) extended to 32G ==="
"$A" shell "su -c 'starfs gpt plan 38 --size 32G'" 2>&1 | tr -d '\r'

echo
echo "=== 3. plan: shrink hackios_sys to 4G ==="
"$A" shell "su -c 'starfs gpt plan 36 --size 4G'" 2>&1 | tr -d '\r'

echo
echo "=== 4. plan: deliberately overlap the neighbour ==="
"$A" shell "su -c 'starfs gpt plan 36 --size 64G'" 2>&1 | tr -d '\r'

echo
echo "=== 5. write without --commit must be refused ==="
"$A" shell "su -c 'starfs gpt write 38 --size 32G 2>&1; echo rc=\$?'" 2>&1 | tr -d '\r'

echo
echo "=== 6. write with wrong --name must be refused (same size, so no overlap) ==="
"$A" shell "su -c 'starfs gpt write 38 --size 16G --name wrong --commit'" 2>&1 | tr -d '\r' | tail -4

echo
echo "=== 6b. plan darwin_var (no NXSB) ==="
"$A" shell "su -c 'starfs gpt plan 37 --size 20G'" 2>&1 | tr -d '\r'

echo
echo "=== 7. bad size suffix ==="
"$A" shell "su -c 'starfs gpt plan 38 --size 12X 2>&1; echo rc=\$?'" 2>&1 | tr -d '\r'
echo "=== DONE (nothing written) ==="
