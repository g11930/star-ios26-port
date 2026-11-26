#!/bin/bash
L=/tmp/s200c.txt
echo "=== candidates ==="
for k in flip vsync vblank fps present swap 'frame ' drawable; do
  echo "$k: $(grep -aci "$k" $L)"
done
echo "=== flip lines ==="; grep -a -i 'flip' $L | tail -6 | cut -c1-160
echo "=== fps lines ==="; grep -a -i 'fps' $L | tail -6 | cut -c1-160