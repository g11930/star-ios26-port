#!/bin/bash
R=/root/star26/s111/work/rootbuild/root/lib
ls -l $R/libannibale.dylib $R/libannibale-sb26.dylib 2>&1 | head -3
echo "=== who mentions the experiment ==="
for f in $R/*.dylib; do
  if strings -n 6 "$f" | grep -q 'sbmetal-experiment'; then
    echo "HIT $(basename $f)"
    strings -n 6 "$f" | grep -n 'sbmetal' | head -6
  fi
done
