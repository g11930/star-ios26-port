#!/bin/bash
for f in /root/star26/s40/work/root/lib/libannibale-sb26.dylib /root/star26/s40/work/root/lib/libannibale.dylib /root/star26/s40/work/root/lib/libannibale-media.dylib; do
  echo "=== $(basename $f)"
  strings -a "$f" 2>/dev/null | grep -iE '^ANNIBALE_.*' | sort -u | head -20
done