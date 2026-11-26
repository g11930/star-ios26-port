#!/bin/bash
for f in /root/star26/s40/work/root/bin/metal_props /root/star26/s40/work/root/bin/annsh; do
  echo "== $(basename $f)"
  strings -a "$f" | grep -iE 'frame|fps|swap|pace' | head -10
done