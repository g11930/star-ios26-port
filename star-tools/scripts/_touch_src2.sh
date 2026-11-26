#!/bin/bash
K=/root/star26/star-native/bsd/dev/star
echo "=== log focaltech lines ==="
grep -a -i 'focaltech\|bit bang\|by hand' /tmp/s175h.txt | head -20
echo "=== source lines ==="
wc -l $K/annibale_goodix.c
echo "=== function list ==="
grep -n '^[a-z_]*(' $K/annibale_goodix.c | head -40