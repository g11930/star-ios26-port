#!/bin/bash
R=/root/star26/s111/work/rootbuild/root/annibale/lib
ls $R 2>/dev/null | head
echo "=== fps-ish strings in shims ==="
for f in $R/*.dylib; do
  n=$(strings -a "$f" 2>/dev/null | grep -icE 'fps|frame_rate|framerate|frames per second')
  [ "$n" -gt 0 ] && { echo "$(basename $f): $n"; strings -a "$f" | grep -iE 'fps|frame_rate|framerate' | head -6; }
done