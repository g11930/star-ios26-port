#!/bin/bash
R=/root/star26/s111/work/rootbuild/root/annibale/bin
ls $R 2>/dev/null | head
for f in $R/*; do
  s=$(strings -a "$f" 2>/dev/null | grep -ic 'frames\|fps\|annibale.frames')
  [ "$s" -gt 0 ] && { echo "== $(basename $f) $s"; strings -a "$f" | grep -i 'frames\|fps\|kern.annibale' | head -8; }
done