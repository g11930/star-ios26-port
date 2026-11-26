#!/bin/bash
L=/root/star26/s111/work/rootbuild/root/lib
for f in "$L"/*.dylib; do
  if strings "$f" | grep -q 'native default device backend mismatch'; then
    echo "carrier: $f"
  fi
done
echo "=== includes ==="
grep -rn 'sb_metal_experiment\|sb_metal_diagnostic_device' /root/star26/hackios-xnu-userland/userland/src/inject/*.m | head -6
</