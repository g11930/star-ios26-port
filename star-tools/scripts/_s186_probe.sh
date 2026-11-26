#!/bin/bash
echo "=== env seen by SpringBoard ==="
grep -a 'kern.annibale.env' /tmp/s186a.txt | tail -3
grep -a 'annibale-env:' /tmp/s186a.txt | sort -u | head -8
echo "=== draws counted? ==="
grep -a -c 'annibalemetal\[SpringBoard' /tmp/s186a.txt
echo "=== code: thumb filters ==="
sed -n '183,300p' /root/star26/hackios-xnu-kernel/tools/userland-driver/annibalemetal_diag.inc