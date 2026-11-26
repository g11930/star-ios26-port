#!/bin/bash
K=/root/star26/star-native/bsd/dev/star/annibale_goodix.c
echo "=== reference trees ==="
ls -d /root/g11930-ref /root/k90-src /root/star26/warsaw-ref /root/ref2 2>/dev/null
echo "=== focaltech mentions in g11930-ref ==="
grep -rl -i 'focaltech' /root/g11930-ref 2>/dev/null | head -8
echo "=== touch files in refs ==="
find /root/g11930-ref /root/k90-src /root/star26/warsaw-ref -iname '*touch*' 2>/dev/null | head -8
echo "=== focaltech_read ==="
sed -n '966,1010p' $K