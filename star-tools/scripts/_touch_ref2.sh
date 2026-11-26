#!/bin/bash
echo "=== g11930-ref docs mention of touch ==="
grep -rn -i 'touch\|触摸' /root/g11930-ref/docs /root/g11930-ref/README.md 2>/dev/null | head -10
echo "=== common/devices/annibale.conf ==="
sed -n '1,60p' /root/g11930-ref/common/devices/annibale.conf 2>/dev/null
echo "=== xnu files list (patches) ==="
ls /root/g11930-ref/xnu/files 2>/dev/null | head -20
</