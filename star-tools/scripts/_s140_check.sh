#!/bin/bash
T=/tmp/s140.txt
strings -n 5 /mnt/c/ios26/s140d-live.bin > $T
echo "=== compiler backend ==="
grep -a 'the compiler library\|backend=' $T | head -8
echo
echo "=== GPU + client opens ==="
grep -a 'THE GPU STAYS ON\|AnnibaleGPU client' $T | head -6
echo
echo "=== window server / CA ==="
for k in 'start window server' 'Initializing CAWindowServer' 'CAWindowServerDisplay' 'swap #' 'P34:' 'Metal failed' 'taken out of the window server'; do
  printf '%-30s %s\n' "$k" "$(grep -ac -- "$k" $T)"
done
echo "=== tail ==="
grep -a '^2025' $T | tail -2
</bash>
