#!/bin/bash
T=/tmp/s135d.txt
echo "=== service / consumers ==="
grep -a 'AnnibaleGPU' $T | head -12
echo
echo "=== window server / CA ==="
for k in 'start window server' 'Initializing CAWindowServer' 'CAWindowServerDisplay' 'swap #' 'P34:' 'Metal failed' 'hardware' 'HARDWARE'; do
  printf "%-28s %s\n" "$k" "$(grep -ac -- "$k" $T)"
done
echo
echo "=== backboardd metal lines ==="
grep -aE 'backboardd.*(Metal|metal|GPU|gpu)' $T | head -10
echo
echo "=== last 3 timestamps ==="
grep -a '^2025' $T | tail -3
</bash>
