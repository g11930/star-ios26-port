#!/bin/bash
echo "=== tail of s176f log ==="
grep -a '2025-12-10 03:07:' /tmp/s176f.txt | tail -14
echo "=== SpringBoard activity counters ==="
grep -ac 'annibalemetal\[SpringBoard' /tmp/s176f.txt
grep -a 'ir3 wait' /tmp/s176f.txt | tail -3
grep -a -c 'compute pipeline' /tmp/s176f.txt
</>
