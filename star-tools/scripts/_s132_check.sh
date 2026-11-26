#!/bin/bash
L=/mnt/c/ios26/s132d-live.bin
strings -n 5 "$L" > /tmp/s132d.txt
echo "=== size ==="; wc -c "$L"
echo "=== adreno steps ==="
grep -a '^adreno' /tmp/s132d.txt | head -25
echo
echo "=== tail of adreno ==="
grep -a '^adreno' /tmp/s132d.txt | tail -6
echo
echo "=== AnnibaleGPU / GPU service ==="
grep -a 'AnnibaleGPU' /tmp/s132d.txt | head -10
echo
echo "=== CA / window server / swaps ==="
for k in 'start window server' 'Initializing CAWindowServer' 'swap #' 'P34:' 'Metal failed' 'framebuffer' 'display 1125'; do
  printf "%-28s %s\n" "$k" "$(grep -ac -- "$k" /tmp/s132d.txt)"
done
echo
echo "=== last timestamps ==="
grep -a '^2025' /tmp/s132d.txt | tail -3
