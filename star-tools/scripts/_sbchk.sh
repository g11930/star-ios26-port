#!/bin/bash
T=/tmp/s136d.txt
echo "=== sandbox / mach-lookup denials ==="
grep -aiE 'deny|sandbox|mach-lookup' $T | head -15
echo
echo "=== what triangle_app did right before its match ==="
sed -n '3840,3860p' $T
echo
echo "=== what backboardd printed around its match ==="
sed -n '3775,3790p' $T
</bash>
