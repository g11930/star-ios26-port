#!/bin/bash
echo "=== dts sources in trees ==="
find /root/star26 /root/k90-src /root/g11930-ref -name '*.dts' -o -name '*.dtsi' 2>/dev/null | head -10
echo "=== dtb blobs ==="
find /root/star26 /root/k90-src -name '*.dtb' 2>/dev/null | head -10
echo "=== touch mentions in loader sources ==="
grep -rn -i 'touch\|goodix\|focal' /root/star26/hackios-xnu-kernel/xnuloader/*.c /root/star26/hackios-xnu-kernel/xnuloader/*.inc 2>/dev/null | head -10
</