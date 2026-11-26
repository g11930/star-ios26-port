#!/bin/bash
echo "=== texImageIOSurface lines (s175d) ==="
grep -a 'texImageIOSurface' /tmp/s175d.txt | head -8
echo "count: $(grep -ac 'texImageIOSurface' /tmp/s175d.txt)"
echo "=== not done ==="
grep -a 'not done' /tmp/s175d.txt | head -6
echo "=== older log s172d ==="
grep -a 'texImageIOSurface' /tmp/s172.txt | head -4
</>
