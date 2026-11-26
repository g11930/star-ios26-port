#!/bin/bash
T=/tmp/s139d.txt
strings -n 5 /mnt/c/ios26/s139d-live.bin > $T
echo "=== sbtrace made the dictionary? ==="
grep -a 'a dictionary made here\|interposing DISABLED\|originals ' $T | head -8
echo
echo "=== GPU service visible now? ==="
grep -an 'no AnnibaleGPU service\|AnnibaleGPU client\|IOSvcDict: match.*Annibale\|IOSvcDict: matchList.*Annibale' $T | head -14
echo
echo "=== window server / CA ==="
for k in 'start window server' 'Initializing CAWindowServer' 'swap #' 'P34:' 'Metal failed'; do
  printf '%-26s %s\n' "$k" "$(grep -ac -- "$k" $T)"
done
echo "=== GPU up ==="
grep -ac 'THE GPU STAYS ON' $T
echo "=== tail ==="
grep -a '^2025' $T | tail -2
</bash>
