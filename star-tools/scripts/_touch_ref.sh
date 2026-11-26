#!/bin/bash
echo "=== k90-src touch ==="
grep -rln -i 'touch\|digitizer\|gt99\|goodix' /root/k90-src 2>/dev/null | head -15
echo "=== g11930-ref tree top ==="
ls /root/g11930-ref 2>/dev/null | head -20
find /root/g11930-ref -maxdepth 2 -type d 2>/dev/null | head -20
</