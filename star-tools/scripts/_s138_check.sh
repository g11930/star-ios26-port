#!/bin/bash
T=/tmp/s138d.txt
strings -n 5 /mnt/c/ios26/s138d-live.bin > $T
echo "=== GPU service now visible? ==="
grep -an 'say .*trace: .*IOServiceMatching("AnnibaleGPU")\|no AnnibaleGPU service\|AnnibaleGPU client' $T | head -10
echo
echo "=== binary dict reading ==="
grep -a 'IOSvcIn: a binary dictionary' $T | head -8
echo
echo "=== window server / CA / swaps ==="
for k in 'start window server' 'Initializing CAWindowServer' 'swap #' 'P34:' 'Metal failed' 'MetalPlugin'; do
  printf '%-26s %s\n' "$k" "$(grep -ac -- "$k" $T)"
done
echo
echo "=== backboardd tail ==="
grep -a 'backboardd\[' $T | tail -4
echo "=== last timestamps ==="
grep -a '^2025' $T | tail -2
</bash>
