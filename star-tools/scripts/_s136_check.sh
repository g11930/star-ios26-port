#!/bin/bash
T=/tmp/s136d.txt
strings -n 5 /mnt/c/ios26/s136d-live.bin > $T
echo "step21 done: $(grep -ac 'adreno: step 21: done' $T)"
echo "=== GPU visible to userland ==="
grep -an 'IOSvc: a match\|no AnnibaleGPU service\|AnnibaleGPU client\|THE GPU STAYS ON' $T | head -10
echo
echo "=== CA ==="
for k in 'start window server' 'Initializing CAWindowServer' 'swap #' 'P34:' 'Metal failed'; do
  printf '%-26s %s\n' "$k" "$(grep -ac -- "$k" $T)"
done
echo
echo "=== tail timestamps ==="
grep -a '^2025' $T | tail -2
</bash>
