#!/bin/bash
L=/mnt/c/ios26/s133d-live.bin
strings -n 5 "$L" > /tmp/s133d.txt
echo "=== size ==="; wc -c "$L"
echo "=== adreno lines ==="
grep -a 'adreno' /tmp/s133d.txt | head -30
echo
echo "=== AnnibaleGPU ==="
grep -a 'AnnibaleGPU' /tmp/s133d.txt | head -8
echo
echo "=== CA ==="
for k in 'start window server' 'Initializing CAWindowServer' 'swap #' 'P34:' 'Metal failed' 'HARDWARE' 'display 1125'; do
  printf "%-28s %s\n" "$k" "$(grep -ac -- "$k" /tmp/s133d.txt)"
done
echo "=== tail ==="
grep -a '^2025' /tmp/s133d.txt | tail -2
</bash>
