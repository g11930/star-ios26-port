#!/bin/bash
K=/root/star26/star-native
echo "=== star device sources ==="
ls -1 $K/bsd/dev/star/ 2>/dev/null | head -40
echo "=== touch/spi related files ==="
grep -rl 'focaltech\|goodix\|FT[0-9]\|touchscreen' $K/bsd/dev/star/ 2>/dev/null | head -20
echo "=== log: touch lines ==="
grep -a -iE 'touch|focal|goodix|ft8|fts' /tmp/s175h.txt | head -20