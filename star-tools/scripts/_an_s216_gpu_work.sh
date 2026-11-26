#!/bin/bash
L=/mnt/d/ios26/s216-mid-072141.bin
echo "=== GPU worked / submissions ==="
grep -a "AnnibaleGPU:" "$L" | grep -E "the GPU worked|submissions in|waits of" | tail -9
echo
echo "=== unlock markers ==="
for k in unlockedEnvironmentMode unlockUIFromSource fDeviceFirstUnlocked; do
  printf "  %-28s %s\n" "$k" "$(grep -a -c "$k" "$L")"
done
echo
echo "=== SpringBoard own applog lines ==="
grep -a -c "SpringBoard\[33" "$L"
echo
echo "=== pac traps latest ==="
grep -a "pac: traps=" "$L" | tail -2
