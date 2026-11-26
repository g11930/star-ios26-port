#!/bin/bash
for f in /tmp/s176g.txt /tmp/s177c.txt /tmp/s172.txt; do
  echo "--- $f"
  echo "gl lines: $(grep -ac 'annibale-gl' $f)"
  grep -a 'annibale-gl' $f | head -4
  echo "IOSurface lines: $(grep -ac 'IOSurface' $f)"
done
</>
